import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/gamification_models.dart';
import '../../gamification/presentation/gamification_page.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  static final List<LeaderboardEntry> _featuredEntries = <LeaderboardEntry>[
    LeaderboardEntry(
      userId: 'featured-shadowpulse',
      displayName: 'ShadowPulse',
      level: 48,
      xp: 18420,
      lifetimeEarned: 3850000,
    ),
    LeaderboardEntry(
      userId: 'featured-novarift',
      displayName: 'NovaRift',
      level: 43,
      xp: 17110,
      lifetimeEarned: 3410000,
    ),
    LeaderboardEntry(
      userId: 'featured-ghostbyte',
      displayName: 'GhostByte',
      level: 39,
      xp: 15940,
      lifetimeEarned: 2980000,
    ),
    LeaderboardEntry(
      userId: 'featured-anonwolf',
      displayName: 'AnonWolf',
      level: 37,
      xp: 14890,
      lifetimeEarned: 2710000,
    ),
    LeaderboardEntry(
      userId: 'featured-pixelnomad',
      displayName: 'PixelNomad',
      level: 34,
      xp: 13660,
      lifetimeEarned: 2440000,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: leaderboard.when(
        data: (entries) {
          final merged = _mergeEntries(entries);
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF173623), Color(0xFF09130D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Top Earners',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'See who is stacking the most coins across videos, movement rewards, referrals, and platform activity.',
                      style: TextStyle(color: Color(0xFF9CB1AA), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _LeaderboardChip(label: 'Global ranking'),
                  _LeaderboardChip(label: 'Coins earned'),
                  _LeaderboardChip(label: 'Updated live'),
                ],
              ),
              const SizedBox(height: 24),
              _LeaderboardPanel(entries: merged),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }

  List<LeaderboardEntry> _mergeEntries(List<LeaderboardEntry> liveEntries) {
    final byId = <String, LeaderboardEntry>{
      for (final entry in _featuredEntries) entry.userId: entry,
      for (final entry in liveEntries) entry.userId: entry,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => b.lifetimeEarned.compareTo(a.lifetimeEarned));
    return merged;
  }
}

class _LeaderboardChip extends StatelessWidget {
  const _LeaderboardChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x161FF5C6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _LeaderboardPanel extends StatelessWidget {
  const _LeaderboardPanel({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final topThree = entries.take(3).toList();

    return Column(
      children: [
        if (topThree.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in topThree)
                SizedBox(
                  width: 240,
                  child: _PodiumCard(
                    entry: entry,
                    rank: topThree.indexOf(entry) + 1,
                  ),
                ),
            ],
          ),
        if (entries.length > 3) ...[
          const SizedBox(height: 16),
          for (final rankedEntry in entries.asMap().entries.skip(3))
            Padding(
              padding: EdgeInsets.only(
                bottom: rankedEntry.key == entries.length - 1 ? 0 : 10,
              ),
              child: _LeaderboardRow(
                entry: rankedEntry.value,
                rank: rankedEntry.key + 1,
              ),
            ),
        ],
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.rank,
  });

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (rank) {
      1 => const Color(0xFFB5FF73),
      2 => const Color(0xFF7CFFB2),
      _ => const Color(0xFF52D987),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101A1D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            entry.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Level ${entry.level} • ${entry.xp} XP',
            style: const TextStyle(color: Color(0xFF9CB1AA)),
          ),
          const SizedBox(height: 14),
          Text(
            '${entry.lifetimeEarned} coins',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${(entry.lifetimeEarned / AppConstants.coinsPerDollar).toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF9CB1AA)),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.rank,
  });

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101A1D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Color(0xFF7CFFB2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName),
                const SizedBox(height: 4),
                Text(
                  'Level ${entry.level} • ${entry.xp} XP',
                  style: const TextStyle(color: Color(0xFF9CB1AA)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.lifetimeEarned} coins',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${(entry.lifetimeEarned / AppConstants.coinsPerDollar).toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF9CB1AA)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
