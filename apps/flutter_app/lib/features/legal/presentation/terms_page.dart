import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const List<({String title, List<String> points})> _sections = [
    (
      title: '1. Eligibility and account access',
      points: [
        'You must provide accurate account information, maintain a secure password, and use only accounts that belong to you.',
        'EarnDash may limit, suspend, or permanently close any account if identity, eligibility, location, device ownership, or reward activity cannot be verified to our satisfaction.',
        'We may refuse service, restrict countries, and require additional verification before allowing offers, ads, referrals, movement rewards, or withdrawals.',
      ],
    ),
    (
      title: '2. Coins, balances, and conversions',
      points: [
        'Coins are promotional platform credits. They do not represent stored cash, a bank balance, or a guaranteed property right.',
        'The current in-app conversion reference is 10,000 coins to 1 USD, but EarnDash may change exchange rates, reward values, payout methods, daily limits, and eligibility rules at any time.',
        'Pending, withdrawable, and lifetime balances are internal status indicators maintained by EarnDash and may be corrected, reduced, reversed, or held after reviews, partner clawbacks, fraud flags, or technical reconciliation.',
      ],
    ),
    (
      title: '3. Reward eligibility and reversals',
      points: [
        'Rewards are earned only when the underlying event is verified by EarnDash and, where applicable, by ad networks, offer providers, device signals, Health Connect, analytics, fraud systems, or manual review.',
        'Rewarded video coins are not owed if an ad fails to load, fails to show, closes early, is duplicated, or cannot be verified.',
        'Offer, referral, movement, and challenge rewards may be rejected, delayed, reversed, moved to pending, or forfeited if the underlying action is incomplete, low quality, duplicated, incentivized improperly, or later disputed by a partner.',
      ],
    ),
    (
      title: '4. Pending periods and withdrawals',
      points: [
        'EarnDash may hold rewards in pending status for security, partner validation, refund windows, advertiser quality checks, or fraud screening. Release schedules are estimates and not guarantees.',
        'Withdrawal requests are subject to minimum thresholds, account age checks, KYC or identity checks, device and IP risk review, manual approval, and method availability.',
        'EarnDash may reject, cancel, void, delay, combine, or permanently deny withdrawal requests in its sole discretion, including after coins appear in your balance.',
      ],
    ),
    (
      title: '5. Anti-fraud, device, and network controls',
      points: [
        'You may not use VPNs, proxies, emulators, spoofing tools, automated tapping, fake step generators, rooted or modified devices, duplicate devices, duplicate IP patterns, or any method intended to manipulate rewards or platform integrity.',
        'EarnDash may collect and process device fingerprints, app integrity signals, coarse location, IP intelligence, activity metadata, Health Connect summaries, ad identifiers when available, and related telemetry to enforce eligibility and prevent abuse.',
        'If our systems flag suspicious behavior, we may shadow-limit rewards, disable withdrawals, anonymize leaderboard visibility, request verification, freeze balances, or terminate the account without prior notice.',
      ],
    ),
    (
      title: '6. Referrals, leaderboards, and community visibility',
      points: [
        'Self-referrals, household loops, device-sharing schemes, recycled installs, or low-quality referred activity are prohibited and may result in referral cancellation or full account action.',
        'Leaderboard placement is informational only. EarnDash may anonymize, remove, or reorder entries for privacy, safety, fraud review, or operational reasons.',
        'If you opt in to leaderboard visibility, you authorize EarnDash to display your chosen profile name, rank, and coin milestones inside the app. If you opt out, we may still display an anonymous or masked entry where needed for ranking integrity.',
      ],
    ),
    (
      title: '7. Content, ads, and partner offers',
      points: [
        'Offers, surveys, videos, and promotional tasks are delivered by third parties. EarnDash is not responsible for partner content, qualification logic, tracking errors, ad availability, or advertiser decisions.',
        'We may add, remove, cap, geo-block, throttle, or deprioritize any earning source at any time without liability.',
        'Completion of a partner task does not guarantee a reward until it is accepted and reconciled by our systems.',
      ],
    ),
    (
      title: '8. Data use and product changes',
      points: [
        'By using EarnDash, you consent to device, reward, and fraud-review processing reasonably necessary to operate the service, investigate abuse, and comply with partner obligations.',
        'EarnDash may modify these terms, the app, reward mechanics, cooldowns, payout methods, eligibility rules, and feature availability at any time. Continued use after changes means you accept the updated version.',
        'We may communicate important account, reward, and security notices in-app, by push notification, or by email, and these communications are part of the service.',
      ],
    ),
    (
      title: '9. Disclaimers and liability limits',
      points: [
        'EarnDash is provided on an as-is and as-available basis. We do not guarantee uninterrupted access, guaranteed earnings, successful tracking, or permanent availability of any earning method.',
        'To the fullest extent permitted by law, EarnDash and its operators are not liable for lost rewards, lost profits, indirect damages, partner errors, payment delays, or account actions taken in good-faith fraud prevention.',
        'If a dispute arises, EarnDash records, fraud signals, partner postbacks, internal ledgers, and moderation decisions will control unless we decide otherwise.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF102218),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x221FF5C6)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please read this carefully before using EarnDash.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12),
                Text(
                  'These terms are designed to protect platform integrity, reward quality, advertiser trust, and our right to review, delay, limit, or reverse rewards whenever misuse or uncertainty exists.',
                  style: TextStyle(color: Color(0xFF9CB1AA), height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            _TermsSection(title: section.title, points: section.points),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'By creating an account, continuing with Google, or using any earning feature, you acknowledge that reward access is conditional, reviewable, and always subject to these terms and our fraud controls.',
              style: TextStyle(color: Color(0xFFB7CDC1), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.points});

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFFB7CDC1),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
