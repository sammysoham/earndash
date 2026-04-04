import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/widgets/coin_reward_celebration.dart';
import '../../admin/presentation/admin_page.dart';
import '../../gamification/presentation/gamification_page.dart';
import '../../referrals/presentation/referrals_page.dart';
import '../../wallet/presentation/wallet_page.dart';
import '../logic/rewarded_ad_service.dart';

Future<void> runRewardFlow(
  BuildContext context,
  WidgetRef ref, {
  required Future<int> Function(RewardedAdService service) action,
  required String successLabel,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
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
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

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
                    const Text('Rewarded ads',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Watch rewarded videos to earn coins that move into pending rewards before becoming withdrawable.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => runRewardFlow(
                        context,
                        ref,
                        action: (service) => service.showRewardedAd(),
                        successLabel: 'You earned',
                      ),
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Watch video'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rewarded ads',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text(
                            'Watch rewarded videos to earn coins that move into pending rewards before becoming withdrawable.',
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => runRewardFlow(
                        context,
                        ref,
                        action: (service) => service.showRewardedAd(),
                        successLabel: 'You earned',
                      ),
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Watch video'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class CompactRewardedAdCard extends ConsumerWidget {
  const CompactRewardedAdCard({
    super.key,
    required this.title,
    required this.body,
    this.highlight = 'Live ads',
  });

  final String title;
  final String body;
  final String highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x221FF5C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x221FF5C6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              highlight,
              style: const TextStyle(
                color: Color(0xFF7CFFB2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(color: Color(0xFF9CB1AA), height: 1.5)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => runRewardFlow(
              context,
              ref,
              action: (service) => service.showRewardedAd(),
              successLabel: 'You earned',
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Watch video'),
          ),
        ],
      ),
    );
  }
}
