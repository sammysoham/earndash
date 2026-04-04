import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth_controller.dart';
import '../../gamification/presentation/gamification_page.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _savingPrivacy = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    final user = session?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account & Privacy')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF143421), Color(0xFF0A1510)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Color(0xFF9FD5AF),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AccountChip(label: user.role),
                          if (user.countryCode != null)
                            _AccountChip(label: user.countryCode!),
                          _AccountChip(
                            label: user.showInLeaderboard
                                ? 'Public leaderboard'
                                : 'Anonymous leaderboard',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102218),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x221FF5C6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leaderboard privacy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose whether your display name appears on public leaderboards. If you opt out, EarnDash will still keep your rank with an anonymous name for fairness.',
                        style: TextStyle(
                          color: Color(0xFF9CB1AA),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: user.showInLeaderboard,
                        onChanged: _savingPrivacy
                            ? null
                            : (value) => _toggleLeaderboardVisibility(value),
                        title:
                            const Text('Show my display name on leaderboards'),
                        subtitle: Text(
                          user.showInLeaderboard
                              ? 'Your profile name can be shown to other users in rankings.'
                              : 'Your ranking stays visible, but your name is masked.',
                        ),
                      ),
                      if (_savingPrivacy)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(minHeight: 4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1B26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Legal & support',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Review the current platform rules, reward limits, pending periods, and fraud policies before using payout-related features.',
                        style: TextStyle(
                          color: Color(0xFF9CB1AA),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/terms'),
                            icon: const Icon(Icons.gavel_rounded),
                            label: const Text('View terms'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/leaderboard'),
                            icon: const Icon(Icons.leaderboard_outlined),
                            label: const Text('Open leaderboard'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _toggleLeaderboardVisibility(bool value) async {
    setState(() => _savingPrivacy = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePreferences(
            showInLeaderboard: value,
          );
      ref.invalidate(leaderboardProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Your display name can now appear on leaderboards.'
                : 'Your leaderboard profile is now anonymous.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPrivacy = false);
      }
    }
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x161FF5C6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
