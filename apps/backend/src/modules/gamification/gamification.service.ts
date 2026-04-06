import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalletTransactionType } from '../wallet/entities/wallet-transaction.entity';
import { WalletService } from '../wallet/wallet.service';
import { UserAchievement } from './entities/user-achievement.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class GamificationService {
  private static readonly DAILY_LOGIN_BONUS_COINS = 100;
  private static readonly MAX_STREAK_FREEZES = 3;

  constructor(
    private readonly usersService: UsersService,
    private readonly walletService: WalletService,
    @InjectRepository(UserAchievement)
    private readonly achievementsRepository: Repository<UserAchievement>,
  ) {}

  async onLogin(userId: string): Promise<void> {
    const user = await this.usersService.getByIdOrFail(userId);
    const today = new Date();
    const lastLogin = user.lastLoginAt;
    let bonusEligible = false;
    let freezeUsed = false;

    if (!lastLogin) {
      user.dailyStreak = 1;
      bonusEligible = true;
    } else {
      const diffInDays = Math.floor(
        (Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()) -
          Date.UTC(lastLogin.getUTCFullYear(), lastLogin.getUTCMonth(), lastLogin.getUTCDate())) /
          (1000 * 60 * 60 * 24),
      );

      if (diffInDays <= 0) {
        return;
      }

      bonusEligible = true;
      if (diffInDays === 1) {
        user.dailyStreak += 1;
      } else if (diffInDays === 2 && user.streakFreezes > 0) {
        user.streakFreezes -= 1;
        user.dailyStreak += 1;
        freezeUsed = true;
      } else {
        user.dailyStreak = 1;
      }
    }

    user.xp += 25;
    user.level = this.levelForXp(user.xp);
    user.lastLoginAt = today;
    if (bonusEligible) {
      const bonusCoins = Math.round(
        GamificationService.DAILY_LOGIN_BONUS_COINS * this.streakMultiplier(user.dailyStreak),
      );
      user.lastDailyBonusClaimAt = today;
      await this.walletService.addPendingCoins(
        userId,
        bonusCoins,
        'DAILY_LOGIN_BONUS',
        `${userId}:${today.toISOString().slice(0, 10)}`,
        {
          streak: user.dailyStreak,
          multiplier: this.streakMultiplier(user.dailyStreak),
          freezeUsed,
        },
      );
      if (
        user.dailyStreak > 0 &&
        user.dailyStreak % 7 === 0 &&
        user.streakFreezes < GamificationService.MAX_STREAK_FREEZES
      ) {
        user.streakFreezes += 1;
      }
    }
    await this.usersService.save(user);

    if (user.dailyStreak >= 7) {
      await this.unlockAchievement(userId, 'streak_7', '7 day streak', 'Logged in 7 days in a row', 100, 250);
    }
  }

  async onOfferCompleted(userId: string, payoutCoins: number): Promise<void> {
    const user = await this.usersService.getByIdOrFail(userId);
    user.xp += Math.max(25, Math.floor(payoutCoins / 20));
    user.level = this.levelForXp(user.xp);
    await this.usersService.save(user);

    await this.unlockAchievement(userId, 'first_offer', 'First offer', 'Completed the first offer', 50, 100);

    const wallet = await this.walletService.getWalletSummary(userId);
    if (wallet.lifetimeEarned >= 1000) {
      await this.unlockAchievement(
        userId,
        'earn_1000',
        'Starter stack',
        'Earned the first 1,000 coins',
        75,
        150,
      );
    }
  }

  async onAdReward(userId: string): Promise<void> {
    const user = await this.usersService.getByIdOrFail(userId);
    user.xp += 10;
    user.level = this.levelForXp(user.xp);
    await this.usersService.save(user);
  }

  async unlockAchievement(
    userId: string,
    achievementKey: string,
    title: string,
    description: string,
    xpReward: number,
    coinsReward: number,
  ): Promise<void> {
    const existing = await this.achievementsRepository.findOne({
      where: { userId, achievementKey },
    });
    if (existing) {
      return;
    }

    await this.achievementsRepository.save(
      this.achievementsRepository.create({
        userId,
        achievementKey,
        title,
        description,
        xpReward,
        coinsReward,
      }),
    );

    const user = await this.usersService.getByIdOrFail(userId);
    user.xp += xpReward;
    user.level = this.levelForXp(user.xp);
    await this.usersService.save(user);

    if (coinsReward > 0) {
      await this.walletService.addAvailableCoins(
        userId,
        coinsReward,
        WalletTransactionType.ADJUSTMENT,
        'ACHIEVEMENT',
        achievementKey,
        { title },
      );
    }
  }

  async getProfile(userId: string) {
    const user = await this.usersService.getByIdOrFail(userId);
    const achievements = await this.achievementsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return {
      level: user.level,
      xp: user.xp,
      dailyStreak: user.dailyStreak,
      streakMultiplier: this.streakMultiplier(user.dailyStreak),
      streakFreezes: user.streakFreezes,
      dailyLoginBonusCoins: Math.round(
        GamificationService.DAILY_LOGIN_BONUS_COINS * this.streakMultiplier(user.dailyStreak),
      ),
      achievements,
    };
  }

  async getLeaderboard() {
    const rows = await this.usersService.leaderboardUsers();

    return rows.map((user) => ({
      userId: user.id,
      displayName: user.showInLeaderboard
        ? user.displayName
        : `Anonymous ${user.id.replace(/-/g, '').slice(-4).toUpperCase()}`,
      level: user.level,
      xp: user.xp,
      lifetimeEarned: user.wallet?.lifetimeEarned ?? 0,
    }));
  }

  private levelForXp(xp: number): number {
    return Math.floor(xp / 500) + 1;
  }

  private streakMultiplier(streak: number): number {
    if (streak >= 30) {
      return 3;
    }
    if (streak >= 14) {
      return 2;
    }
    if (streak >= 7) {
      return 1.5;
    }
    if (streak >= 3) {
      return 1.2;
    }
    return 1;
  }
}
