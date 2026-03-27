import 'package:flutter/material.dart';

class OfferwallPage extends StatelessWidget {
  const OfferwallPage({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = <_ComingSoonOfferwall>[
      _ComingSoonOfferwall(
        name: 'MyLead',
        subtitle: 'Surveys, installs, and CPA tasks',
        accent: Color(0xFF59F3C3),
      ),
      _ComingSoonOfferwall(
        name: 'CPAGrip',
        subtitle: 'Content unlocks and partner offers',
        accent: Color(0xFF85A7FF),
      ),
      _ComingSoonOfferwall(
        name: 'More providers',
        subtitle: 'More earning partners will unlock over time',
        accent: Color(0xFFFF8FCF),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Offerwalls')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF173623), Color(0xFF09130D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offer partners are on the way', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text(
                  'New offer partners are being added to bring surveys, installs, and featured tasks into EarnDash. Until then, you can keep earning through rewarded videos and movement rewards.',
                  style: TextStyle(color: Color(0xFF9CB1AA), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ComingSoonCard(card: card),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1B26),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available right now', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('Rewarded videos are live in the Watch & Earn tab.'),
                SizedBox(height: 8),
                Text('Move & Earn also helps you build coins through daily activity, goals, and streaks.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonOfferwall {
  const _ComingSoonOfferwall({
    required this.name,
    required this.subtitle,
    required this.accent,
  });

  final String name;
  final String subtitle;
  final Color accent;
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.card});

  final _ComingSoonOfferwall card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: card.accent.withValues(alpha: 0.14),
            ),
            child: Center(
              child: Text(
                card.name.substring(0, 1),
                style: TextStyle(
                  color: card.accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(card.subtitle, style: const TextStyle(color: Color(0xFF9CB1AA))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: card.accent.withValues(alpha: 0.12),
            ),
            child: Text(
              'Upcoming',
              style: TextStyle(
                color: card.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
