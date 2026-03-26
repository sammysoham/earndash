import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ads/presentation/rewarded_ad_panel.dart';
import '../../auth/logic/auth_controller.dart';
import '../../gamification/presentation/gamification_page.dart';
import '../../move_earn/presentation/move_earn_page.dart';
import '../../referrals/presentation/referrals_page.dart';
import '../../wallet/presentation/wallet_page.dart';

class HomeOverviewPage extends ConsumerWidget {
  const HomeOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final wallet = ref.watch(walletProvider);
    final profile = ref.watch(gamificationProfileProvider);
    final referrals = ref.watch(referralOverviewProvider);
    final movement = ref.watch(moveEarnProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return ListView(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 24 : 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFF143220), Color(0xFF09140E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0x2027FF87),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Live demo workspace', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB9FFD6))),
                  ),
                  const SizedBox(height: 18),
                  Text('Welcome, ${session?.user.displayName ?? 'earner'}', style: TextStyle(fontSize: isCompact ? 30 : 40, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                    session?.user.isAdmin == true
                        ? 'Monitor balances, test reward loops, and review admin-facing health from one greener control room.'
                        : 'Mix Move & Earn with rewarded videos, grow your wallet, and keep daily streak momentum alive.',
                    style: const TextStyle(color: Color(0xFF9CB1AA), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/move'),
                        child: const Text('Open Move & Earn'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/ads'),
                        child: const Text('Watch videos for coins'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/wallet'),
                        child: const Text('Open wallet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _AsyncMetricChip(label: 'Balance', value: wallet.when(data: (value) => '${value.withdrawableCoins} coins', loading: () => '...', error: (_, __) => '--')),
                      _AsyncMetricChip(label: 'Pending', value: wallet.when(data: (value) => '${value.pendingCoins} coins', loading: () => '...', error: (_, __) => '--')),
                      _AsyncMetricChip(label: 'Today steps', value: movement.when(data: (value) => '${value.todaySteps}', loading: () => '...', error: (_, __) => '--')),
                      _AsyncMetricChip(label: 'Daily streak', value: profile.when(data: (value) => '${value.dailyStreak} days', loading: () => '...', error: (_, __) => '--')),
                      _AsyncMetricChip(label: 'Referrals', value: referrals.when(data: (value) => '${value.referredEarners}', loading: () => '...', error: (_, __) => '--')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _FeatureStrip(
              isCompact: isCompact,
              children: [
                _FeatureCallout(
                  eyebrow: 'Move live',
                  title: 'Walking and running now power a real daily earn loop.',
                  body: 'Track steps, hit safe caps, stack streaks, and trigger a temporary 2x boost from rewarded ads.',
                  accent: const Color(0xFF00E676),
                ),
                _FeatureCallout(
                  eyebrow: 'Safe payouts',
                  title: 'Track pending, withdrawable, and lifetime earnings in one place.',
                  body: 'The wallet stays synced with reward settlement, XP updates, and payout requests.',
                  accent: const Color(0xFF79FFAE),
                ),
                _FeatureCallout(
                  eyebrow: 'Growth loop',
                  title: 'Referrals and streaks give the app a stronger habit loop.',
                  body: 'Users can share a code, earn referral commission, and stay active with daily progression.',
                  accent: const Color(0xFFB5FF73),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isCompact ? double.infinity : (constraints.maxWidth - 16) / 2,
                  child: _ActionPanel(
                    title: 'Account state',
                    lines: [
                      'Referral code: ${session?.user.referralCode ?? '--'}',
                      'Country: ${session?.user.countryCode ?? '--'}',
                      'Fraud score: ${session?.user.fraudScore ?? 0} / 100',
                    ],
                  ),
                ),
                SizedBox(
                  width: isCompact ? double.infinity : (constraints.maxWidth - 16) / 2,
                  child: const _ActionPanel(
                    title: 'Demo notes',
                    lines: [
                      'Move & Earn is now live with safe daily caps and streak bonuses.',
                      'Rewarded videos are the primary live earn flow.',
                      'Offerwalls are visible as coming soon.',
                      'Admin demo exposes analytics cards and fraud-sensitive metrics.',
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const RewardedAdPanel(),
          ],
        );
      },
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.isCompact, required this.children});

  final bool isCompact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final child in children)
          SizedBox(
            width: isCompact ? double.infinity : 280,
            child: child,
          ),
      ],
    );
  }
}

class _FeatureCallout extends StatelessWidget {
  const _FeatureCallout({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B26),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: TextStyle(fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: Color(0xFF9CB1AA), height: 1.5)),
        ],
      ),
    );
  }
}

class _AsyncMetricChip extends StatelessWidget {
  const _AsyncMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x181FF5C6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CB1AA))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final line in lines) ...[
            Text(line, style: const TextStyle(color: Color(0xFF9CB1AA))),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
