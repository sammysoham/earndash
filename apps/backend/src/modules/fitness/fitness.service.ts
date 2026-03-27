import { Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { UsersService } from '../users/users.service';
import { WalletService } from '../wallet/wallet.service';
import { SyncActivityDto } from './dto/sync-activity.dto';
import { ActivityDayRecord, UserActivityStats } from './entities/user-activity.entity';
import { UserActivityRepository } from './repositories/user-activity.repository';

interface RankInfo {
  rank: string;
  rankMultiplier: number;
  rankDailyCap: number;
}

@Injectable()
export class FitnessService {
  constructor(
    private readonly activityRepository: UserActivityRepository,
    private readonly usersService: UsersService,
    private readonly walletService: WalletService,
    private readonly auditService: AuditService,
  ) {}

  async getOverview(userId: string) {
    const [user, stats] = await Promise.all([
      this.usersService.getByIdOrFail(userId),
      this.ensureStats(userId),
    ]);
    return this.buildOverview(user.level, stats);
  }

  async syncActivity(userId: string, dto: SyncActivityDto) {
    const [user, stats] = await Promise.all([
      this.usersService.getByIdOrFail(userId),
      this.ensureStats(userId),
    ]);
    const rankInfo = this.rankForLevel(user.level);
    const normalizedHistory = this.normalizeHistory(dto.weeklyHistory);
    const today =
      normalizedHistory[normalizedHistory.length - 1] ?? this.blankDay(dto.todayDateKey);
    const trustedSource = this.isTrustedStepSource(dto.source);

    if (stats.todayDateKey !== dto.todayDateKey) {
      stats.rewardedCoinsToday = 0;
      stats.rewardedStepsToday = 0;
    }

    const suspicious = this.isSuspicious(today);
    stats.todayDateKey = dto.todayDateKey;
    stats.todaySteps = today.steps;
    stats.distanceKm = today.distanceKm.toFixed(2);
    stats.activeMinutes = today.activeMinutes;
    stats.walkMinutes = today.walkMinutes;
    stats.runMinutes = today.runMinutes;
    stats.calories = today.calories;
    stats.weeklyHistory = normalizedHistory;
    stats.trackingAvailable = dto.supported;
    stats.trackingPermissionGranted = dto.permissionGranted;
    stats.trackingStatus = dto.status;
    stats.trackingSource = dto.source;
    stats.trackingMessage = dto.message ?? null;
    stats.goalStreakDays = this.computeGoalStreak(normalizedHistory, stats.dailyGoalSteps);
    stats.suspiciousActivityBlocked = suspicious || !trustedSource;
    stats.antiCheatMessage = !trustedSource
      ? 'Connect Health Connect or keep step-counter tracking active to unlock verified movement rewards.'
      : suspicious
          ? 'Activity looked unrealistic, so new walking rewards were held for review.'
          : null;

    const boostActive = !!stats.stepBoostEndsAt && stats.stepBoostEndsAt.getTime() > Date.now();
    if (!stats.suspiciousActivityBlocked) {
      const rewardableSteps = Math.min(today.steps, rankInfo.rankDailyCap);
      const completedBlocks = Math.floor(rewardableSteps / 1000);
      const previouslyRewardedBlocks = Math.floor(stats.rewardedStepsToday / 1000);
      const newBlocks = Math.max(0, completedBlocks - previouslyRewardedBlocks);

      if (newBlocks > 0) {
        const rewardSteps = newBlocks * 1000;
        const rewardCoins = Math.round(
          newBlocks * 10 * rankInfo.rankMultiplier * (boostActive ? 2 : 1),
        );
        stats.rewardedStepsToday += rewardSteps;
        stats.rewardedCoinsToday += rewardCoins;

        await this.walletService.addPendingCoins(
          userId,
          rewardCoins,
          'MOVE_EARN',
          `${dto.todayDateKey}:${stats.rewardedStepsToday}`,
          { todaySteps: today.steps, boostActive },
        );
        await this.auditService.log(userId, 'MOVE_EARN_SYNC_REWARDED', 'USER', userId, {
          coins: rewardCoins,
          steps: rewardSteps,
          boostActive,
        });
      }
    }

    await this.activityRepository.save(stats);
    return this.buildOverview(user.level, stats);
  }

  async activateBoost(userId: string) {
    const [user, stats] = await Promise.all([
      this.usersService.getByIdOrFail(userId),
      this.ensureStats(userId),
    ]);
    stats.stepBoostEndsAt = new Date(Date.now() + 30 * 1000);
    await this.activityRepository.save(stats);
    await this.auditService.log(userId, 'MOVE_EARN_BOOST_ACTIVATED', 'USER', userId, {});
    return this.buildOverview(user.level, stats);
  }

  private async ensureStats(userId: string): Promise<UserActivityStats> {
    const existing = await this.activityRepository.findByUserId(userId);
    if (existing) {
      return existing;
    }

    const today = this.dateKey(new Date());
    return this.activityRepository.save(
      this.activityRepository.create({
        userId,
        todayDateKey: today,
        weeklyHistory: this.buildBlankWeek(today),
        trackingStatus: 'unknown',
        trackingSource: 'step_counter',
      }),
    );
  }

  private async buildOverview(level: number, stats: UserActivityStats) {
    const rankInfo = this.rankForLevel(level);
    const weeklyHistory = this.normalizeHistory(stats.weeklyHistory ?? []);
    const weeklySteps = weeklyHistory.reduce((sum, item) => sum + item.steps, 0);
    const leaderboardRows = await this.activityRepository.topWeekly();
    const leaderboard = leaderboardRows
      .map((row) => {
        const history = this.normalizeHistory(row.weeklyHistory ?? []);
        return {
          displayName: row.user.displayName,
          steps: history.reduce((sum, item) => sum + item.steps, 0),
          distanceKm: history.reduce((sum, item) => sum + item.distanceKm, 0),
          rank: this.rankForLevel(row.user.level).rank,
        };
      })
      .sort((a, b) => b.steps - a.steps)
      .slice(0, 20);

    const weeklyRunDistance = weeklyHistory.reduce(
      (sum, item) => sum + this.runDistance(item),
      0,
    );
    const activeDays = weeklyHistory.filter((item) => item.steps >= stats.dailyGoalSteps).length;
    const boostActive = !!stats.stepBoostEndsAt && stats.stepBoostEndsAt.getTime() > Date.now();

    return {
      todaySteps: stats.todaySteps,
      distanceKm: Number(stats.distanceKm),
      activeMinutes: stats.activeMinutes,
      walkMinutes: stats.walkMinutes,
      runMinutes: stats.runMinutes,
      calories: stats.calories,
      rewardedCoinsToday: stats.rewardedCoinsToday,
      rewardedStepsToday: stats.rewardedStepsToday,
      dailyRewardStepCap: 10000,
      dailyGoalSteps: stats.dailyGoalSteps,
      weeklySteps,
      weeklyGoalSteps: stats.dailyGoalSteps * 7,
      goalStreakDays: stats.goalStreakDays,
      rank: rankInfo.rank,
      rankMultiplier: rankInfo.rankMultiplier,
      rankDailyCap: rankInfo.rankDailyCap,
      stepBoostActive: boostActive,
      stepBoostMultiplier: boostActive ? 2 : 1,
      stepBoostEndsAt: stats.stepBoostEndsAt,
      weeklyChart: weeklyHistory.map((item) => ({
        label: item.label,
        steps: item.steps,
        distanceKm: item.distanceKm,
      })),
      weeklyChallenges: [
        {
          title: 'Walk 30,000 steps',
          progress: weeklySteps,
          target: 30000,
          rewardCoins: 180,
          unit: 'steps',
          completed: weeklySteps >= 30000,
        },
        {
          title: 'Run 5 km',
          progress: weeklyRunDistance,
          target: 5,
          rewardCoins: 140,
          unit: 'km',
          completed: weeklyRunDistance >= 5,
        },
        {
          title: 'Stay active 5 days',
          progress: activeDays,
          target: 5,
          rewardCoins: 120,
          unit: 'days',
          completed: activeDays >= 5,
        },
      ],
      leaderboard,
      suspiciousActivityBlocked: stats.suspiciousActivityBlocked,
      antiCheatMessage: stats.antiCheatMessage,
      trackingAvailable: stats.trackingAvailable,
      trackingPermissionGranted: stats.trackingPermissionGranted,
      trackingStatus: stats.trackingStatus,
      trackingSource: stats.trackingSource,
      trackingMessage: stats.trackingMessage,
    };
  }

  private rankForLevel(level: number): RankInfo {
    if (level >= 20) {
      return { rank: 'Elite', rankMultiplier: 1.5, rankDailyCap: 20000 };
    }
    if (level >= 10) {
      return { rank: 'Gold', rankMultiplier: 1.25, rankDailyCap: 15000 };
    }
    if (level >= 5) {
      return { rank: 'Silver', rankMultiplier: 1.1, rankDailyCap: 12000 };
    }
    return { rank: 'Bronze', rankMultiplier: 1, rankDailyCap: 10000 };
  }

  private normalizeHistory(weeklyHistory: ActivityDayRecord[]): ActivityDayRecord[] {
    const sorted = [...weeklyHistory].sort((a, b) => a.dateKey.localeCompare(b.dateKey));
    return sorted.length > 7 ? sorted.slice(sorted.length - 7) : sorted;
  }

  private buildBlankWeek(todayKey: string): ActivityDayRecord[] {
    const today = new Date(`${todayKey}T00:00:00.000Z`);
    return Array.from({ length: 7 }, (_, index) => {
      const date = new Date(today);
      date.setUTCDate(today.getUTCDate() - (6 - index));
      return this.blankDay(this.dateKey(date));
    });
  }

  private blankDay(dateKey: string): ActivityDayRecord {
    const date = new Date(`${dateKey}T00:00:00.000Z`);
    const labels: Record<number, string> = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      0: 'Sun',
    };

    return {
      dateKey,
      label: labels[date.getUTCDay()] ?? 'Day',
      steps: 0,
      distanceKm: 0,
      activeMinutes: 0,
      walkMinutes: 0,
      runMinutes: 0,
      calories: 0,
    };
  }

  private isSuspicious(day: ActivityDayRecord): boolean {
    if (day.activeMinutes <= 0 || day.distanceKm <= 0) {
      return false;
    }
    const speedKmPerHour = day.distanceKm / (day.activeMinutes / 60);
    return speedKmPerHour > 18 || (day.steps > 25000 && day.activeMinutes < 45);
  }

  private isTrustedStepSource(source: string): boolean {
    const normalized = source.toLowerCase();
    return (
      normalized.includes('health_connect') ||
      normalized.includes('android_foreground_service') ||
      normalized.includes('step_counter')
    );
  }

  private computeGoalStreak(history: ActivityDayRecord[], goal: number): number {
    let streak = 0;
    for (let index = history.length - 1; index >= 0; index -= 1) {
      if (history[index].steps >= goal) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  private runDistance(day: ActivityDayRecord): number {
    if (day.runMinutes <= 0 || day.activeMinutes <= 0) {
      return 0;
    }
    return day.distanceKm * (day.runMinutes / day.activeMinutes);
  }

  private dateKey(value: Date): string {
    const year = value.getUTCFullYear().toString().padStart(4, '0');
    const month = (value.getUTCMonth() + 1).toString().padStart(2, '0');
    const day = value.getUTCDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
