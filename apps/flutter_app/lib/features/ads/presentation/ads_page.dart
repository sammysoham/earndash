import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'banner_ad_strip.dart';
import 'rewarded_ad_panel.dart';

class AdsPage extends ConsumerWidget {
  const AdsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF163622), Color(0xFF09120D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Rewarded videos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              Text(
                'Watch short rewarded videos to build your pending balance, then let rewards clear into withdrawals over time.',
                style: TextStyle(color: Color(0xFF9CB1AA), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _AdStat(title: 'Reward range', value: '5-20 coins'),
            _AdStat(title: 'Hold period', value: '14 days'),
            _AdStat(title: 'Video type', value: 'Rewarded only'),
            _AdStat(title: 'Inventory', value: 'Video + banner'),
          ],
        ),
        const SizedBox(height: 24),
        const RewardedAdPanel(),
        const SizedBox(height: 24),
        const BannerAdStrip(),
        const SizedBox(height: 24),
        const CompactRewardedAdCard(
          title: 'Extra ad slot',
          body: 'Use this extra slot any time you want another rewarded video without leaving the earning flow.',
          highlight: 'More inventory',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1B26),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How ad rewards work', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              Text('1. Load a rewarded video.'),
              SizedBox(height: 6),
              Text('2. Watch the ad through completion.'),
              SizedBox(height: 6),
              Text('3. EarnDash validates the reward and credits your pending balance.'),
              SizedBox(height: 6),
              Text('4. Your wallet, XP, and progress update automatically after the reward is recorded.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdStat extends StatelessWidget {
  const _AdStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B26),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF9CB1AA))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
