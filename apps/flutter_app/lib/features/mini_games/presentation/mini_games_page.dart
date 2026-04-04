import 'package:flutter/material.dart';

class MiniGamesPage extends StatelessWidget {
  const MiniGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF173623), Color(0xFF09120D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini Games',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                'A casual arcade corner is on the way with quick games, tiny rewards, and fun skill-based sessions built for short breaks.',
                style: TextStyle(color: Color(0xFF9CB1AA), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF101A1D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x221FF5C6)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_esports_outlined,
                      color: Color(0xFF7CFFB2), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Coming Soon',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'We are polishing a lightweight arcade experience for EarnDash. The first drop will include fast casual challenges inspired by carrom, pool, and table tennis.',
                style: TextStyle(color: Color(0xFF9CB1AA), height: 1.5),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ComingSoonChip(label: 'Skill-based fun'),
                  _ComingSoonChip(label: 'Tiny reward caps'),
                  _ComingSoonChip(label: 'Short daily sessions'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x161FF5C6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7CFFB2),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
