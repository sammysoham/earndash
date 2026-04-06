import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/gamification_models.dart';
import '../../auth/logic/auth_controller.dart';

final gamificationProfileProvider = FutureProvider<GamificationProfile>((ref) {
  return ref.read(apiClientProvider).getGamificationProfile();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.read(apiClientProvider).getLeaderboard();
});

class GamificationPage extends ConsumerWidget {
  const GamificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gamificationProfileProvider);
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Levels and achievements')),
      body: profile.when(
        data: (gamification) => ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF153825), Color(0xFF0A130E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${gamification.level}',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${gamification.xp} XP • ${gamification.dailyStreak} day streak • ${gamification.streakMultiplier.toStringAsFixed(gamification.streakMultiplier.truncateToDouble() == gamification.streakMultiplier ? 0 : 1)}x login bonus',
                    style: const TextStyle(color: Color(0xFF9FD5AF)),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: (gamification.xp % 500) / 500,
                      backgroundColor: const Color(0xFF1A2D23),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoCard(
                  title: 'Daily login bonus',
                  value: '${gamification.dailyLoginBonusCoins} coins',
                  subtitle: 'Your next verified login reward at the current streak.',
                ),
                _InfoCard(
                  title: 'Streak multiplier',
                  value:
                      '${gamification.streakMultiplier.toStringAsFixed(gamification.streakMultiplier.truncateToDouble() == gamification.streakMultiplier ? 0 : 1)}x',
                  subtitle: 'Applied to your daily login bonus.',
                ),
                _InfoCard(
                  title: 'Streak freezes',
                  value: '${gamification.streakFreezes}',
                  subtitle: 'Automatically saves one missed day when available.',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: gamification.achievements
                  .map(
                    (achievement) => Container(
                      width: 280,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101A1D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E402B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.description,
                            style: const TextStyle(color: Color(0xFF9CB1AA)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Top earners snapshot',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go('/leaderboard'),
                icon: const Icon(Icons.leaderboard_outlined),
                label: const Text('Open full leaderboard'),
              ),
            ),
            const SizedBox(height: 16),
            leaderboard.when(
              data: (entries) => _LeaderboardPanel(entries: entries),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
            ),
          ],
        ),
        error: (error, _) => Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101A1D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x221FF5C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF9CB1AA))),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9CB1AA), height: 1.4),
          ),
        ],
      ),
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
          Text(
            '${entry.lifetimeEarned} coins',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
