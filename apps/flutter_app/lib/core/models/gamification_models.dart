class GamificationProfile {
  GamificationProfile({
    required this.level,
    required this.xp,
    required this.dailyStreak,
    required this.streakMultiplier,
    required this.streakFreezes,
    required this.dailyLoginBonusCoins,
    required this.achievements,
  });

  final int level;
  final int xp;
  final int dailyStreak;
  final double streakMultiplier;
  final int streakFreezes;
  final int dailyLoginBonusCoins;
  final List<AchievementModel> achievements;

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      streakMultiplier: (json['streakMultiplier'] as num? ?? 1).toDouble(),
      streakFreezes: json['streakFreezes'] as int? ?? 0,
      dailyLoginBonusCoins: json['dailyLoginBonusCoins'] as int? ?? 100,
      achievements: (json['achievements'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => AchievementModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AchievementModel {
  AchievementModel({required this.title, required this.description});

  final String title;
  final String description;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.level,
    required this.xp,
    required this.lifetimeEarned,
  });

  final String userId;
  final String displayName;
  final int level;
  final int xp;
  final int lifetimeEarned;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      level: json['level'] as int,
      xp: json['xp'] as int,
      lifetimeEarned: json['lifetimeEarned'] as int,
    );
  }
}
