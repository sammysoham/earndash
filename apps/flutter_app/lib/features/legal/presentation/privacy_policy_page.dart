import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const List<({String title, List<String> points})> _sections = [
    (
      title: '1. What EarnDash collects',
      points: [
        'EarnDash may collect account information such as your email address, display name, referral code, and sign-in method.',
        'We may collect device and app information such as device fingerprint, app version, advertising identifier when available, platform type, and operating system details.',
        'We may collect network and location-related signals such as IP address, country detection, anti-VPN or proxy signals, and coarse fraud-prevention indicators.',
      ],
    ),
    (
      title: '2. Rewards, wallet, and account activity',
      points: [
        'EarnDash stores wallet balances, pending releases, ad rewards, offer completions, withdrawals, referral events, streak activity, and leaderboard preferences to operate the service.',
        'We may maintain audit logs and moderation notes when rewards, withdrawals, or account actions are reviewed.',
        'Reward-related data may be retained as long as reasonably necessary for reconciliation, fraud review, and dispute handling.',
      ],
    ),
    (
      title: '3. Movement and fitness data',
      points: [
        'If you use Move & Earn, EarnDash may process step counts, activity summaries, active minutes, motion classifications, and Health Connect summaries when permission is granted.',
        'Movement data is used to calculate eligibility, improve tracking accuracy, and detect unrealistic or manipulated activity.',
        'Movement rewards may be held, limited, or denied if device signals cannot be verified to our satisfaction.',
      ],
    ),
    (
      title: '4. Why we use your information',
      points: [
        'We use data to create accounts, secure sessions, verify rewards, enforce cooldowns, manage streaks, review withdrawals, and keep the product working reliably.',
        'We also use data to detect fraud, duplicate devices, suspicious IP patterns, VPN use, referral abuse, and other behavior that may put the platform or partners at risk.',
        'We may use product usage information to improve app features, diagnostics, user support, and service performance.',
      ],
    ),
    (
      title: '5. Sharing with third parties',
      points: [
        'EarnDash may share limited information with service providers and partners that support authentication, hosting, analytics, ad delivery, offer attribution, notifications, and fraud prevention.',
        'Third-party offer and ad partners may apply their own data and eligibility policies when you interact with their services.',
        'We may disclose information when required by law, to protect users, or to defend the rights and operations of EarnDash.',
      ],
    ),
    (
      title: '6. Leaderboards and visibility',
      points: [
        'If you opt in to leaderboard visibility, your display name, ranking, and related progress may appear inside the app.',
        'If you opt out, EarnDash may still show an anonymous or masked leaderboard entry to preserve ranking integrity and fairness.',
        'Leaderboard entries may be hidden, reordered, or removed during moderation, safety review, or fraud investigation.',
      ],
    ),
    (
      title: '7. VPN, fraud, and abuse controls',
      points: [
        'EarnDash may block or restrict accounts using VPNs, proxies, automated tools, fake step generators, or other methods that weaken reward integrity.',
        'Fraud and abuse reviews may affect balances, reward availability, withdrawals, and account access.',
        'Some information may be retained longer where necessary for fraud prevention, legal compliance, payout review, or auditability.',
      ],
    ),
    (
      title: '8. Your choices',
      points: [
        'You may update your display name and choose whether it appears publicly on leaderboards.',
        'You can choose whether to use movement-related features and permissions, though disabling them may limit eligibility for Move & Earn rewards.',
        'You may request account review or support assistance through EarnDash support channels, subject to our operational and legal obligations.',
      ],
    ),
    (
      title: '9. Security and policy updates',
      points: [
        'EarnDash uses reasonable technical and organizational safeguards, but no system can guarantee complete security.',
        'We may update this Privacy Policy from time to time, and continued use of EarnDash after an update means you accept the revised policy.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              color: const Color(0xFF0E1B26),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x221FF5C6)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy matters because trust matters.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12),
                Text(
                  'This policy explains what EarnDash collects, why it is used, how fraud and reward systems rely on it, and what visibility choices you control inside the app.',
                  style: TextStyle(color: Color(0xFF9CB1AA), height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            _PrivacySection(title: section.title, points: section.points),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF102218),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'By using EarnDash, you acknowledge that some data processing is necessary to operate rewards, enforce anti-fraud protections, secure partner relationships, and maintain platform integrity.',
              style: TextStyle(color: Color(0xFFB7CDC1), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.points});

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A14),
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
