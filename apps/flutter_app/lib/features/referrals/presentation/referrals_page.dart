import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/referral_overview.dart';
import '../../auth/logic/auth_controller.dart';

final referralOverviewProvider = FutureProvider<ReferralOverview>((ref) {
  return ref.read(apiClientProvider).getReferralOverview();
});

class ReferralsPage extends ConsumerWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(referralOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: overview.when(
        data: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;

            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A1D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your referral code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      SelectableText(
                        data.referralCode,
                        style: TextStyle(fontSize: isCompact ? 26 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF59F3C3)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Earn 10% of lifetime offer earnings from every valid referred user. Self-referrals are blocked.'),
                      if (data.invitedByDisplayName != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'You joined through ${data.invitedByDisplayName}.',
                          style: const TextStyle(color: Color(0xFF90DFAF)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ReferralStat(label: 'Referred earners', value: '${data.referredEarners}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 32) / 3),
                    _ReferralStat(label: 'Commission earned', value: '${data.commissionEarnedCoins} coins', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 32) / 3),
                    _ReferralStat(label: 'Abuse flags', value: '${data.abuseFlags}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 32) / 3),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Active referrals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...data.activeReferrals.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101A1D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('${entry.lifetimeEarnedCoins} coins earned'),
                              const SizedBox(height: 4),
                              Text('${entry.commissionCoins} coins to you'),
                              const SizedBox(height: 4),
                              Text(entry.status, style: const TextStyle(color: Color(0xFF9CB1AA))),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w700))),
                              Text('${entry.lifetimeEarnedCoins} coins earned'),
                              const SizedBox(width: 16),
                              Text('${entry.commissionCoins} coins to you'),
                              const SizedBox(width: 16),
                              Text(entry.status, style: const TextStyle(color: Color(0xFF9CB1AA))),
                            ],
                          ),
                  ),
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
}

class _ReferralStat extends StatelessWidget {
  const _ReferralStat({required this.label, required this.value, required this.width});

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101A1D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CB1AA))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
