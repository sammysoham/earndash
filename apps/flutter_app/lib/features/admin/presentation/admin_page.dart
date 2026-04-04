import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/admin_entities.dart';
import '../../../core/models/admin_metrics.dart';
import '../../auth/logic/auth_controller.dart';
import '../../referrals/presentation/referrals_page.dart';
import '../../wallet/presentation/wallet_page.dart';

final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) {
  return ref.read(apiClientProvider).getAdminMetrics();
});

final adminUsersProvider = FutureProvider<List<AdminUserSummary>>((ref) {
  return ref.read(apiClientProvider).getAdminUsers();
});

final adminWithdrawalsProvider =
    FutureProvider<List<AdminWithdrawalRequest>>((ref) {
  return ref.read(apiClientProvider).getAdminWithdrawals();
});

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    if (session?.user.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Admin access required')),
      );
    }

    final metrics = ref.watch(adminMetricsProvider);
    final users = ref.watch(adminUsersProvider);
    final withdrawals = ref.watch(adminWithdrawalsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Withdrawals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            metrics.when(
              data: _buildOverview,
              error: (error, _) => Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            users.when(
              data: _buildUsers,
              error: (error, _) => Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            withdrawals.when(
              data: _buildWithdrawals,
              error: (error, _) => Center(child: Text('$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(AdminMetrics data) {
    return ListView(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _AdminMetric(label: 'Users', value: '${data.totalUsers}'),
            _AdminMetric(label: 'DAU', value: '${data.dailyActiveUsers}'),
            _AdminMetric(
              label: 'Offer conversion',
              value: '${data.offerConversionRate.toStringAsFixed(1)}%',
            ),
            _AdminMetric(
              label: 'Withdrawal rate',
              value: '${data.withdrawalRate.toStringAsFixed(1)}%',
            ),
            _AdminMetric(
              label: 'Fraud rate',
              value: '${data.fraudRate.toStringAsFixed(1)}%',
            ),
            _AdminMetric(
              label: 'Average LTV',
              value: '\$${data.averageLtvUsd.toStringAsFixed(2)}',
            ),
            _AdminMetric(
              label: 'Revenue / user',
              value: '\$${data.revenuePerUserUsd.toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF102218),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations status',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Review users, approve or reject withdrawal requests, gift coins, and block suspicious accounts directly in the app.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsers(List<AdminUserSummary> users) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2419),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusPill(
                    label: user.isBlocked ? 'Blocked' : user.role,
                    color: user.isBlocked
                        ? const Color(0xFFFF8E8E)
                        : const Color(0xFF5BFF9D),
                  ),
                  if (user.isNewUser)
                    const _StatusPill(
                      label: 'New user',
                      color: Color(0xFFB4FF74),
                    ),
                  _StatusPill(
                    label: 'Fraud ${user.fraudScore}',
                    color: user.fraudScore >= 60
                        ? const Color(0xFFFFB366)
                        : const Color(0xFF79FDC1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${user.email} • ${user.countryCode} • ${user.referralCode}',
                style: const TextStyle(color: Color(0xFFA4BEAF)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MiniStat(label: 'Total', value: '${user.totalCoins}'),
                  _MiniStat(
                      label: 'Withdrawable',
                      value: '${user.withdrawableCoins}'),
                  _MiniStat(label: 'Pending', value: '${user.pendingCoins}'),
                  _MiniStat(label: 'Lifetime', value: '${user.lifetimeEarned}'),
                  _MiniStat(label: 'Streak', value: '${user.dailyStreak}d'),
                ],
              ),
              if (user.referredByDisplayName != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Referred by ${user.referredByDisplayName}',
                  style: const TextStyle(color: Color(0xFF8FD9AE)),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: user.role == 'ADMIN'
                        ? null
                        : () => _giftCoinsDialog(user),
                    icon: const Icon(Icons.card_giftcard_outlined),
                    label: const Text('Gift coins'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        user.role == 'ADMIN' ? null : () => _toggleBlock(user),
                    icon: Icon(user.isBlocked
                        ? Icons.lock_open_outlined
                        : Icons.block_outlined),
                    label: Text(user.isBlocked ? 'Unblock' : 'Block'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawals(List<AdminWithdrawalRequest> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2419),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Text(
                    item.userDisplayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusPill(
                    label: item.status,
                    color: item.status == 'PENDING_ADMIN_REVIEW'
                        ? const Color(0xFFFFD66E)
                        : item.status == 'REJECTED'
                            ? const Color(0xFFFF8E8E)
                            : const Color(0xFF5BFF9D),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.coins} coins • ${item.method} • ${item.destination}',
                style: const TextStyle(color: Color(0xFFA4BEAF)),
              ),
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.note!,
                    style: const TextStyle(color: Color(0xFF8FD9AE))),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (item.status != 'APPROVED')
                    OutlinedButton(
                      onPressed: () => _setWithdrawalStatus(item, 'APPROVED'),
                      child: const Text('Approve'),
                    ),
                  if (item.status == 'APPROVED' || item.status == 'QUEUED')
                    OutlinedButton(
                      onPressed: () => _setWithdrawalStatus(item, 'PAID'),
                      child: const Text('Mark paid'),
                    ),
                  if (item.status != 'REJECTED')
                    OutlinedButton(
                      onPressed: () => _setWithdrawalStatus(item, 'REJECTED'),
                      child: const Text('Reject'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _giftCoinsDialog(AdminUserSummary user) async {
    final coinsController = TextEditingController(text: '250');
    final noteController = TextEditingController(text: 'Launch bonus');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gift coins to ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gift'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(apiClientProvider).giftCoins(
          targetUserId: user.id,
          coins: int.parse(coinsController.text),
          note: noteController.text,
        );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminMetricsProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(referralOverviewProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gifted coins to ${user.displayName}')),
    );
  }

  Future<void> _toggleBlock(AdminUserSummary user) async {
    await ref.read(apiClientProvider).setUserBlocked(
          targetUserId: user.id,
          blocked: !user.isBlocked,
        );
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminMetricsProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isBlocked
              ? '${user.displayName} unblocked'
              : '${user.displayName} blocked',
        ),
      ),
    );
  }

  Future<void> _setWithdrawalStatus(
    AdminWithdrawalRequest item,
    String status,
  ) async {
    await ref.read(apiClientProvider).updateWithdrawalStatus(
          withdrawalId: item.id,
          status: status,
        );
    ref.invalidate(adminWithdrawalsProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminMetricsProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Withdrawal updated to $status')),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2419),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA4BEAF))),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1415FF9B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA4BEAF))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
