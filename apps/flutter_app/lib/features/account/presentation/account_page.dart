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
  bool _savingProfile = false;
  bool _requestingDeletion = false;
  final TextEditingController _displayNameController = TextEditingController();
  String? _loadedDisplayName;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    final user = session?.user;
    if (user != null && _loadedDisplayName != user.displayName) {
      _loadedDisplayName = user.displayName;
      _displayNameController.text = user.displayName;
    }

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
                    color: const Color(0xFF101A1D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick the name you want to use around the app. This is also the name shown on leaderboards when public visibility is enabled.',
                        style: TextStyle(
                          color: Color(0xFF9CB1AA),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _displayNameController,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'Enter a custom profile name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _savingProfile ? null : _saveDisplayName,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _savingProfile ? 'Saving...' : 'Save profile name',
                        ),
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
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/privacy'),
                            icon: const Icon(Icons.privacy_tip_outlined),
                            label: const Text('Privacy policy'),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF201012),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x33FF6B6B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danger zone',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Request account deletion from inside the app. This will immediately restrict access while the request is reviewed and processed.',
                        style: TextStyle(
                          color: Color(0xFFCCB5B7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _requestingDeletion ? null : _requestDeletion,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          _requestingDeletion
                              ? 'Submitting request...'
                              : 'Request account deletion',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9E9E),
                          side: const BorderSide(color: Color(0x66FF6B6B)),
                        ),
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

  Future<void> _saveDisplayName() async {
    final nextName = _displayNameController.text.trim();
    if (nextName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name must be at least 3 characters long.'),
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePreferences(
            displayName: nextName,
          );
      ref.invalidate(leaderboardProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name updated.')),
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
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _requestDeletion() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This sends an account deletion request and immediately restricts your access while the request is reviewed.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Tell us why you want to delete the account',
              ),
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
            child: const Text('Submit request'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    setState(() => _requestingDeletion = true);
    try {
      await ref.read(authControllerProvider.notifier).requestAccountDeletion(
            reason: reasonController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion request submitted.'),
        ),
      );
      context.go('/login');
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
      reasonController.dispose();
      if (mounted) {
        setState(() => _requestingDeletion = false);
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
