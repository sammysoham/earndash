import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/widgets/coin_reward_celebration.dart';
import '../../admin/presentation/admin_page.dart';
import '../../gamification/presentation/gamification_page.dart';
import '../../referrals/presentation/referrals_page.dart';
import '../../wallet/presentation/wallet_page.dart';
import '../logic/rewarded_ad_service.dart';

class RewardedAdPanel extends ConsumerWidget {
  const RewardedAdPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B26),
            borderRadius: BorderRadius.circular(24),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rewarded ads', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Watch rewarded videos for quick coins, or trigger a rewarded interstitial for a bigger burst.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _runRewardFlow(
                        context,
                        ref,
                        action: (service) => service.showRewardedAd(),
                        successLabel: 'You earned',
                      ),
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Watch video'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _runRewardFlow(
                        context,
                        ref,
                        action: (service) => service.showRewardedInterstitialAd(),
                        successLabel: 'Big reward unlocked:',
                      ),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Watch bonus ad'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rewarded ads', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text(
                            'Watch rewarded videos for quick coins, or trigger a rewarded interstitial for a bigger burst.',
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _runRewardFlow(
                            context,
                            ref,
                            action: (service) => service.showRewardedAd(),
                            successLabel: 'You earned',
                          ),
                          icon: const Icon(Icons.ondemand_video_rounded),
                          label: const Text('Watch video'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _runRewardFlow(
                            context,
                            ref,
                            action: (service) => service.showRewardedInterstitialAd(),
                            successLabel: 'Big reward unlocked:',
                          ),
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Watch bonus ad'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _runRewardFlow(
    BuildContext context,
    WidgetRef ref, {
    required Future<int> Function(RewardedAdService service) action,
    required String successLabel,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final reward = await action(ref.read(rewardedAdServiceProvider));
    ref.invalidate(walletProvider);
    ref.invalidate(gamificationProfileProvider);
    ref.invalidate(leaderboardProvider);
    ref.invalidate(adminMetricsProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(referralOverviewProvider);
    if (context.mounted) {
      await showCoinRewardCelebration(context, coins: reward);
      await LocalNotificationsService.instance.showRewardEarned(
        coins: reward,
        title: 'Coins added',
        body: successLabel,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('$successLabel $reward coins')),
      );
    }
  }
}
