import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/fitness_models.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/widgets/coin_reward_celebration.dart';
import '../../ads/logic/rewarded_ad_service.dart';
import '../../ads/presentation/banner_ad_strip.dart';
import '../../ads/presentation/rewarded_ad_panel.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/logic/auth_controller.dart';
import '../../gamification/presentation/gamification_page.dart';
import '../../wallet/presentation/wallet_page.dart';

final moveEarnProvider = FutureProvider<MoveEarnOverview>((ref) {
  return ref.read(apiClientProvider).getMoveEarnOverview();
});

class MoveEarnPage extends ConsumerStatefulWidget {
  const MoveEarnPage({super.key});

  @override
  ConsumerState<MoveEarnPage> createState() => _MoveEarnPageState();
}

class _MoveEarnPageState extends ConsumerState<MoveEarnPage> {
  bool _syncing = false;
  bool _boosting = false;
  Timer? _ticker;
  DateTime _countdownNow = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _countdownNow = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(moveEarnProvider);
    ref.watch(rewardedAdClockProvider);
    final adCooldownEndsAt = ref.watch(rewardedAdCooldownProvider);
    final adCooldownSeconds = _secondsUntilNextRewardedAd(adCooldownEndsAt);

    return Scaffold(
      appBar: AppBar(title: const Text('Move & Earn')),
      body: overview.when(
        data: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final wideCardWidth =
                isCompact ? double.infinity : (constraints.maxWidth - 16) / 2;

            return ListView(
              children: [
                _MoveHero(
                  data: data,
                  isCompact: isCompact,
                  boostCountdownText: _boostCountdownText(data.stepBoostEndsAt),
                  onWalkSync: _syncing ? null : () => _syncActivity(data),
                  onRunSync: _syncing ? null : () => _refreshOverview(),
                  onBoost: _boosting || adCooldownSeconds > 0
                      ? null
                      : () => _activateBoost(),
                  adCooldownText: adCooldownSeconds > 0
                      ? 'Next rewarded boost video unlocks in ${adCooldownSeconds}s.'
                      : '1,000 steps = 10 coins, and one rewarded video can activate a 2x multiplier for 30 seconds.',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _FitnessStatCard(
                      width: isCompact
                          ? (constraints.maxWidth - 16) / 2
                          : (constraints.maxWidth - 48) / 4,
                      label: 'Today\'s steps',
                      value: '${data.todaySteps}',
                      accent: const Color(0xFF00E676),
                      icon: Icons.directions_walk_rounded,
                    ),
                    _FitnessStatCard(
                      width: isCompact
                          ? (constraints.maxWidth - 16) / 2
                          : (constraints.maxWidth - 48) / 4,
                      label: 'Distance',
                      value: '${data.distanceKm.toStringAsFixed(2)} km',
                      accent: const Color(0xFF79FFAE),
                      icon: Icons.route_rounded,
                    ),
                    _FitnessStatCard(
                      width: isCompact
                          ? (constraints.maxWidth - 16) / 2
                          : (constraints.maxWidth - 48) / 4,
                      label: 'Active minutes',
                      value: '${data.activeMinutes} min',
                      accent: const Color(0xFFB5FF73),
                      icon: Icons.local_fire_department_outlined,
                    ),
                    _FitnessStatCard(
                      width: isCompact
                          ? (constraints.maxWidth - 16) / 2
                          : (constraints.maxWidth - 48) / 4,
                      label: 'Calories',
                      value: '${data.calories}',
                      accent: const Color(0xFFE7FF9A),
                      icon: Icons.bolt_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const CompactRewardedAdCard(
                  title: 'Need a coin boost while you move?',
                  body:
                      'Use a rewarded video to activate a short 2x step multiplier while your verified movement rewards keep building.',
                  highlight: 'Move booster',
                ),
                const SizedBox(height: 24),
                const BannerAdStrip(),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: wideCardWidth,
                      child: _WeeklyChartCard(
                        title: 'Weekly steps',
                        subtitle:
                            '${data.weeklySteps} / ${data.weeklyGoalSteps} steps this week',
                        metricLabelBuilder: (item) =>
                            '${(item.steps / 1000).toStringAsFixed(1)}k',
                        valueBuilder: (item) => item.steps.toDouble(),
                        colorBuilder: (item) =>
                            item.steps >= data.dailyGoalSteps
                                ? const Color(0xFF00E676)
                                : const Color(0xFF1F6F48),
                        items: data.weeklyChart,
                      ),
                    ),
                    SizedBox(
                      width: wideCardWidth,
                      child: _WeeklyChartCard(
                        title: 'Distance chart',
                        subtitle:
                            '${data.weeklyChart.fold<double>(0, (sum, item) => sum + item.distanceKm).toStringAsFixed(1)} km moved this week',
                        metricLabelBuilder: (item) =>
                            item.distanceKm.toStringAsFixed(1),
                        valueBuilder: (item) => item.distanceKm,
                        colorBuilder: (item) => item.distanceKm >= 4
                            ? const Color(0xFF7CFFB2)
                            : const Color(0xFF285E40),
                        items: data.weeklyChart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: wideCardWidth,
                      child: _GoalPanel(data: data),
                    ),
                    SizedBox(
                      width: wideCardWidth,
                      child: _RankCard(data: data),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Weekly challenges',
                  subtitle:
                      'Complete movement goals to stack safe bonus coins and streak momentum.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final challenge in data.weeklyChallenges)
                      SizedBox(
                        width: isCompact
                            ? double.infinity
                            : (constraints.maxWidth - 32) / 3,
                        child: _ChallengeCard(challenge: challenge),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: wideCardWidth,
                      child: _LeaderBoardCard(data: data),
                    ),
                    SizedBox(
                      width: wideCardWidth,
                      child: _AntiCheatPanel(data: data),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        error: (error, _) => Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _syncActivity(MoveEarnOverview current) async {
    setState(() => _syncing = true);
    try {
      final updated = await ref.read(apiClientProvider).syncMoveActivity();
      final earned =
          max(0, updated.rewardedCoinsToday - current.rewardedCoinsToday);
      ref.invalidate(moveEarnProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(gamificationProfileProvider);
      ref.invalidate(leaderboardProvider);
      ref.invalidate(adminMetricsProvider);
      ref.invalidate(adminUsersProvider);
      if (mounted && earned > 0) {
        await showCoinRewardCelebration(context, coins: earned);
        await LocalNotificationsService.instance.showRewardEarned(
          coins: earned,
          title: 'Move reward unlocked',
          body: 'Activity synced.',
        );
      }
      if (mounted) {
        final msg = earned > 0
            ? 'Activity synced: +$earned coins'
            : 'Activity synced. Keep moving to unlock the next 1,000-step reward.';
        final messenger = ScaffoldMessenger.of(context);
        await LocalNotificationsService.instance.showMoveUpdate(msg);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _refreshOverview() async {
    ref.invalidate(moveEarnProvider);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await LocalNotificationsService.instance.showMoveUpdate(
        'Live activity refreshed from your device sensors.',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Refreshed live device activity.')),
      );
    }
  }

  Future<void> _activateBoost() async {
    setState(() => _boosting = true);
    try {
      final adReward =
          await ref.read(rewardedAdServiceProvider).showRewardedAd();
      await ref.read(apiClientProvider).activateStepBoost();
      ref.invalidate(moveEarnProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(gamificationProfileProvider);
      ref.invalidate(adminMetricsProvider);
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        await showCoinRewardCelebration(context, coins: adReward);
        await LocalNotificationsService.instance.showRewardEarned(
          coins: adReward,
          title: 'Step boost activated',
          body: '2x multiplier is live for 30 seconds.',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '2x step boost is live for 30 seconds. Video reward: +$adReward pending coins'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _boosting = false);
      }
    }
  }

  String _boostCountdownText(DateTime? endsAt) {
    if (endsAt == null) {
      return '';
    }

    final remaining = endsAt.difference(_countdownNow);
    if (remaining.inSeconds <= 0) {
      return 'Boost ready';
    }

    final seconds = remaining.inSeconds.toString().padLeft(2, '0');
    return '2x boost active • $seconds s left';
  }

  int _secondsUntilNextRewardedAd(DateTime? cooldownEndsAt) {
    if (cooldownEndsAt == null) {
      return 0;
    }

    final remaining = cooldownEndsAt.difference(_countdownNow).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

class _MoveHero extends StatelessWidget {
  const _MoveHero({
    required this.data,
    required this.isCompact,
    required this.boostCountdownText,
    required this.adCooldownText,
    required this.onWalkSync,
    required this.onRunSync,
    required this.onBoost,
  });

  final MoveEarnOverview data;
  final bool isCompact;
  final String boostCountdownText;
  final String adCooldownText;
  final VoidCallback? onWalkSync;
  final VoidCallback? onRunSync;
  final VoidCallback? onBoost;

  @override
  Widget build(BuildContext context) {
    final progress =
        (data.todaySteps / data.dailyGoalSteps).clamp(0, 1).toDouble();
    final weeklyProgress =
        (data.weeklySteps / data.weeklyGoalSteps).clamp(0, 1).toDouble();

    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF12311F), Color(0xFF0A1510)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2200E676),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const _HeroBadge(
                  label: 'Fitness live', icon: Icons.favorite_rounded),
              _HeroBadge(
                  label: '${data.rank} rank',
                  icon: Icons.workspace_premium_rounded),
              _HeroBadge(
                  label: '${(data.rankMultiplier).toStringAsFixed(1)}x base',
                  icon: Icons.auto_graph_rounded),
              _HeroBadge(
                  label: 'Daily cap ${data.rankDailyCap}',
                  icon: Icons.verified_user_outlined),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Move more. Earn safely.',
            style: TextStyle(
              fontSize: isCompact ? 30 : 40,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Walking, running, verified step tracking, short boost windows, streaks, and anti-cheat controls now work together in one fitness workspace.',
            style: TextStyle(color: Color(0xFF9FD5AF), height: 1.6),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ProgressRing(
                  progress: progress,
                  steps: data.todaySteps,
                  goal: data.dailyGoalSteps),
              SizedBox(
                width: isCompact ? double.infinity : 460,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.rewardedCoinsToday} coins earned from activity today',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rewarded steps ${data.rewardedStepsToday}/${data.rankDailyCap} • ${data.walkMinutes} min walking • ${data.runMinutes} min running',
                      style: const TextStyle(color: Color(0xFF9FD5AF)),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: weeklyProgress,
                        backgroundColor: const Color(0x1EFFFFFF),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF00E676)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Weekly goal progress: ${data.weeklySteps}/${data.weeklyGoalSteps} steps',
                      style: const TextStyle(color: Color(0xFF9FD5AF)),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onWalkSync,
                          icon: const Icon(Icons.sync_rounded),
                          label: const Text('Sync device'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onRunSync,
                          icon: const Icon(Icons.sensors_outlined),
                          label: const Text('Refresh live'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onBoost,
                          icon: const Icon(Icons.ondemand_video_rounded),
                          label: Text(
                            data.stepBoostActive
                                ? 'Boost running'
                                : onBoost == null
                                    ? 'Boost cooldown'
                                    : 'Watch ad for boost',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.stepBoostActive && data.stepBoostEndsAt != null
                          ? boostCountdownText
                          : adCooldownText,
                      style: TextStyle(
                        color: data.stepBoostActive
                            ? const Color(0xFFC9FFC8)
                            : const Color(0xFF9FD5AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tracking: ${data.trackingStatus} • source: ${data.trackingSource}',
                      style: const TextStyle(
                        color: Color(0xFF9FD5AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x162DFF93),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CFFBE)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.steps,
    required this.goal,
  });

  final double progress;
  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 196,
            height: 196,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x3316FF88), Color(0x1106110B)],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 950),
            builder: (context, value, _) => SizedBox(
              width: 176,
              height: 176,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 14,
                backgroundColor: const Color(0x2227FF87),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$steps',
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text('steps today',
                  style: TextStyle(color: Color(0xFF9FD5AF))),
              const SizedBox(height: 8),
              Text(
                '$goal goal',
                style: const TextStyle(
                  color: Color(0xFFB5FF73),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFF90B69E))),
      ],
    );
  }
}

class _FitnessStatCard extends StatelessWidget {
  const _FitnessStatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Color(0xFF90B69E))),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.metricLabelBuilder,
    required this.valueBuilder,
    required this.colorBuilder,
  });

  final String title;
  final String subtitle;
  final List<WeeklyActivityBar> items;
  final String Function(WeeklyActivityBar item) metricLabelBuilder;
  final double Function(WeeklyActivityBar item) valueBuilder;
  final Color Function(WeeklyActivityBar item) colorBuilder;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
        1, (current, item) => max(current, valueBuilder(item)));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF90B69E))),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final item in items)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          metricLabelBuilder(item),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF90B69E)),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                              begin: 0, end: valueBuilder(item) / maxValue),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, value, _) => Container(
                            height: 124 * value + 12,
                            decoration: BoxDecoration(
                              color: colorBuilder(item),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(item.label,
                            style: const TextStyle(color: Color(0xFF90B69E))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.data});

  final MoveEarnOverview data;

  @override
  Widget build(BuildContext context) {
    final goalProgress =
        (data.todaySteps / data.dailyGoalSteps).clamp(0, 1).toDouble();
    final streakMilestones = <({int day, int reward})>[
      (day: 3, reward: 30),
      (day: 7, reward: 90),
      (day: 30, reward: 400),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily goal & streak',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '${data.todaySteps}/${data.dailyGoalSteps} steps today • ${data.goalStreakDays}-day streak',
            style: const TextStyle(color: Color(0xFF90B69E)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: goalProgress,
              backgroundColor: const Color(0x221CFF87),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final milestone in streakMilestones)
                Container(
                  width: 112,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: data.goalStreakDays >= milestone.day
                        ? const Color(0x1527FF87)
                        : const Color(0x101C3024),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: data.goalStreakDays >= milestone.day
                          ? const Color(0x3327FF87)
                          : const Color(0x14FFFFFF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${milestone.day} days',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${milestone.reward}',
                        style: TextStyle(
                          color: data.goalStreakDays >= milestone.day
                              ? const Color(0xFF00E676)
                              : const Color(0xFF90B69E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final WeeklyChallengeModel challenge;

  @override
  Widget build(BuildContext context) {
    final progress =
        (challenge.progress / challenge.target).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (challenge.completed)
                const Icon(Icons.verified_rounded, color: Color(0xFFB5FF73)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${challenge.progress.toStringAsFixed(challenge.unit == 'steps' ? 0 : 1)} / ${challenge.target.toStringAsFixed(challenge.unit == 'steps' ? 0 : 1)} ${challenge.unit}',
            style: const TextStyle(color: Color(0xFF90B69E)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: const Color(0x221CFF87),
              valueColor: AlwaysStoppedAnimation(
                challenge.completed
                    ? const Color(0xFFB5FF73)
                    : const Color(0xFF00E676),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${challenge.rewardCoins} bonus coins',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFFB5FF73)),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.data});

  final MoveEarnOverview data;

  @override
  Widget build(BuildContext context) {
    const ranks = <String>['Bronze', 'Silver', 'Gold', 'Elite'];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fitness rank',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Higher activity unlocks bigger step caps, better multipliers, and stronger event access.',
            style: TextStyle(color: Color(0xFF90B69E)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final rank in ranks)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: rank == data.rank
                        ? const Color(0x1A00E676)
                        : const Color(0x101C3024),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: rank == data.rank
                          ? const Color(0x4400E676)
                          : const Color(0x14FFFFFF),
                    ),
                  ),
                  child: Text(
                    rank,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: rank == data.rank
                          ? const Color(0xFF00E676)
                          : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _RankMeta(
                  label: 'Daily cap', value: '${data.rankDailyCap} steps'),
              _RankMeta(
                  label: 'Multiplier',
                  value: '${data.rankMultiplier.toStringAsFixed(1)}x'),
              _RankMeta(
                  label: 'Boost',
                  value: data.stepBoostActive ? '30s live' : 'Ready'),
              _RankMeta(
                  label: 'Goal streak', value: '${data.goalStreakDays} days'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankMeta extends StatelessWidget {
  const _RankMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF90B69E))),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _LeaderBoardCard extends StatelessWidget {
  const _LeaderBoardCard({required this.data});

  final MoveEarnOverview data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step leaderboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Top walkers and runners this week.',
              style: TextStyle(color: Color(0xFF90B69E))),
          const SizedBox(height: 16),
          for (final entry in data.leaderboard.asMap().entries)
            Padding(
              padding: EdgeInsets.only(
                  bottom: entry.key == data.leaderboard.length - 1 ? 0 : 10),
              child: _LeaderboardTile(rank: entry.key + 1, item: entry.value),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.item});

  final int rank;
  final ActivityLeaderboardEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11261A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x1400E676),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF00E676)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${item.steps} steps • ${item.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Color(0xFF90B69E)),
                ),
              ],
            ),
          ),
          Text(
            item.rank,
            style: const TextStyle(
                color: Color(0xFFB5FF73), fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AntiCheatPanel extends StatelessWidget {
  const _AntiCheatPanel({required this.data});

  final MoveEarnOverview data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E15),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Anti-cheat guardrails',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Move & Earn applies step verification, safe speed limits, boost windows, and daily caps before coins are granted.',
            style: TextStyle(color: Color(0xFF90B69E), height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            data.trackingPermissionGranted
                ? 'Live sensor access is enabled.'
                : 'Enable activity access on your phone to read real steps.',
            style: TextStyle(
              color: data.trackingPermissionGranted
                  ? const Color(0xFF7CFFB2)
                  : const Color(0xFFFFC08A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GuardrailPill(label: 'Speed detection'),
              _GuardrailPill(label: 'Daily cap'),
              _GuardrailPill(label: 'Sensor validation'),
              _GuardrailPill(label: 'Optional GPS checks'),
            ],
          ),
          if (data.antiCheatMessage != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2B1E13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data.antiCheatMessage!,
                style: const TextStyle(color: Color(0xFFFFC08A)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuardrailPill extends StatelessWidget {
  const _GuardrailPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x101C3024),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
