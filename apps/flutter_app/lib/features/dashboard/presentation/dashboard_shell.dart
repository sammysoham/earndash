import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/logic/auth_controller.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({required this.child, super.key});

  final Widget child;

  static const _items = <({String label, IconData icon, String path})>[
    (label: 'Home', icon: Icons.space_dashboard_outlined, path: '/dashboard'),
    (label: 'Move & Earn', icon: Icons.directions_walk_outlined, path: '/move'),
    (label: 'Watch & Earn', icon: Icons.ondemand_video_outlined, path: '/ads'),
    (label: 'Offerwall', icon: Icons.local_activity_outlined, path: '/offerwall'),
    (label: 'Wallet', icon: Icons.account_balance_wallet_outlined, path: '/wallet'),
    (label: 'Withdrawals', icon: Icons.payments_outlined, path: '/withdrawals'),
    (label: 'Referrals', icon: Icons.group_add_outlined, path: '/referrals'),
    (label: 'Levels', icon: Icons.emoji_events_outlined, path: '/gamification'),
    (label: 'Admin', icon: Icons.admin_panel_settings_outlined, path: '/admin'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final location = GoRouterState.of(context).uri.path;
    final items = session?.user.isAdmin == true ? _items : _items.where((item) => item.path != '/admin').toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2419),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const EarndashBrand(compact: true),
                                  const SizedBox(height: 4),
                                  Text(session?.user.displayName ?? 'Operator', style: const TextStyle(color: Color(0xFF9CB1AA))),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () async {
                                await ref.read(authControllerProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                                  for (final item in items)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        avatar: Icon(item.icon, size: 18),
                                        label: Text(item.label),
                                        selected: location == item.path,
                                        onSelected: (_) => context.go(item.path),
                                      ),
                                    ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  width: 280,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2419),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EarndashBrand(compact: true),
                      const SizedBox(height: 8),
                      Text(session?.user.displayName ?? 'Operator', style: const TextStyle(color: Color(0xFF9CB1AA))),
                      const SizedBox(height: 28),
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            selected: location == item.path,
                            selectedTileColor: const Color(0x1A59F3C3),
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            onTap: () => context.go(item.path),
                          ),
                        ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                    child: child,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
