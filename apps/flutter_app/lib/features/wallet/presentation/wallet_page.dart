import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/wallet_summary.dart';
import '../../admin/presentation/admin_page.dart';
import '../../auth/logic/auth_controller.dart';
import '../../gamification/presentation/gamification_page.dart';

final walletProvider = FutureProvider<WalletSummary>((ref) {
  return ref.read(apiClientProvider).getWallet();
});

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: wallet.when(
        data: (summary) => LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;

            return ListView(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _WalletMetric(label: 'Total coins', value: '${summary.totalCoins}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 16) / 2),
                    _WalletMetric(label: 'Pending', value: '${summary.pendingCoins}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 16) / 2),
                    _WalletMetric(label: 'Withdrawable', value: '${summary.withdrawableCoins}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 16) / 2),
                    _WalletMetric(label: 'Lifetime earned', value: '${summary.lifetimeEarned}', width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 16) / 2),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A1D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Settle pending rewards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            const Text('Demo mode shortcut: move all pending coins to withdrawable so you can test the payout flow.'),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final settled = await ref.read(apiClientProvider).settlePendingRewards();
                                ref.invalidate(walletProvider);
                                ref.invalidate(adminMetricsProvider);
                                ref.invalidate(gamificationProfileProvider);
                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(settled == 0 ? 'No pending rewards to settle' : '$settled coins are now withdrawable')),
                                  );
                                }
                              },
                              child: const Text('Settle now'),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Settle pending rewards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 8),
                                  Text('Demo mode shortcut: move all pending coins to withdrawable so you can test the payout flow.'),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final settled = await ref.read(apiClientProvider).settlePendingRewards();
                                ref.invalidate(walletProvider);
                                ref.invalidate(adminMetricsProvider);
                                ref.invalidate(gamificationProfileProvider);
                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(settled == 0 ? 'No pending rewards to settle' : '$settled coins are now withdrawable')),
                                  );
                                }
                              },
                              child: const Text('Settle now'),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                const Text('Recent transactions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...summary.transactionHistory.map(
                  (transaction) => Container(
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
                              Text(transaction.type, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('${transaction.coins} coins'),
                              const SizedBox(height: 4),
                              Text(transaction.status, style: const TextStyle(color: Color(0xFF9CB1AA))),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: Text(transaction.type)),
                              Text('${transaction.coins} coins'),
                              const SizedBox(width: 12),
                              Text(transaction.status, style: const TextStyle(color: Color(0xFF9CB1AA))),
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

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({required this.label, required this.value, required this.width});

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
