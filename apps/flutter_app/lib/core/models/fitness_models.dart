class MoveEarnOverview {
  MoveEarnOverview({
    required this.todaySteps,
    required this.distanceKm,
    required this.activeMinutes,
    required this.walkMinutes,
    required this.runMinutes,
    required this.calories,
    required this.rewardedCoinsToday,
    required this.rewardedStepsToday,
    required this.dailyRewardStepCap,
    required this.dailyGoalSteps,
    required this.weeklySteps,
    required this.weeklyGoalSteps,
    required this.goalStreakDays,
    required this.rank,
    required this.rankMultiplier,
    required this.rankDailyCap,
    required this.stepBoostActive,
    required this.stepBoostMultiplier,
    required this.stepBoostEndsAt,
    required this.weeklyChart,
    required this.weeklyChallenges,
    required this.leaderboard,
    required this.suspiciousActivityBlocked,
    required this.antiCheatMessage,
    required this.trackingAvailable,
    required this.trackingPermissionGranted,
    required this.trackingStatus,
    required this.trackingSource,
    required this.trackingMessage,
  });

  final int todaySteps;
  final double distanceKm;
  final int activeMinutes;
  final int walkMinutes;
  final int runMinutes;
  final int calories;
  final int rewardedCoinsToday;
  final int rewardedStepsToday;
  final int dailyRewardStepCap;
  final int dailyGoalSteps;
  final int weeklySteps;
  final int weeklyGoalSteps;
  final int goalStreakDays;
  final String rank;
  final double rankMultiplier;
  final int rankDailyCap;
  final bool stepBoostActive;
  final double stepBoostMultiplier;
  final DateTime? stepBoostEndsAt;
  final List<WeeklyActivityBar> weeklyChart;
  final List<WeeklyChallengeModel> weeklyChallenges;
  final List<ActivityLeaderboardEntry> leaderboard;
  final bool suspiciousActivityBlocked;
  final String? antiCheatMessage;
  final bool trackingAvailable;
  final bool trackingPermissionGranted;
  final String trackingStatus;
  final String trackingSource;
  final String? trackingMessage;

  factory MoveEarnOverview.fromJson(Map<String, dynamic> json) {
    return MoveEarnOverview(
      todaySteps: json['todaySteps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      activeMinutes: json['activeMinutes'] as int? ?? 0,
      walkMinutes: json['walkMinutes'] as int? ?? 0,
      runMinutes: json['runMinutes'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
      rewardedCoinsToday: json['rewardedCoinsToday'] as int? ?? 0,
      rewardedStepsToday: json['rewardedStepsToday'] as int? ?? 0,
      dailyRewardStepCap: json['dailyRewardStepCap'] as int? ?? 10000,
      dailyGoalSteps: json['dailyGoalSteps'] as int? ?? 5000,
      weeklySteps: json['weeklySteps'] as int? ?? 0,
      weeklyGoalSteps: json['weeklyGoalSteps'] as int? ?? 35000,
      goalStreakDays: json['goalStreakDays'] as int? ?? 0,
      rank: json['rank'] as String? ?? 'Bronze',
      rankMultiplier: (json['rankMultiplier'] as num? ?? 1).toDouble(),
      rankDailyCap: json['rankDailyCap'] as int? ?? 10000,
      stepBoostActive: json['stepBoostActive'] as bool? ?? false,
      stepBoostMultiplier: (json['stepBoostMultiplier'] as num? ?? 1).toDouble(),
      stepBoostEndsAt: json['stepBoostEndsAt'] == null
          ? null
          : DateTime.parse(json['stepBoostEndsAt'] as String),
      weeklyChart: (json['weeklyChart'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => WeeklyActivityBar.fromJson(item as Map<String, dynamic>))
          .toList(),
      weeklyChallenges: (json['weeklyChallenges'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => WeeklyChallengeModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      leaderboard: (json['leaderboard'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => ActivityLeaderboardEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      suspiciousActivityBlocked: json['suspiciousActivityBlocked'] as bool? ?? false,
      antiCheatMessage: json['antiCheatMessage'] as String?,
      trackingAvailable: json['trackingAvailable'] as bool? ?? false,
      trackingPermissionGranted: json['trackingPermissionGranted'] as bool? ?? false,
      trackingStatus: json['trackingStatus'] as String? ?? 'unknown',
      trackingSource: json['trackingSource'] as String? ?? 'unknown',
      trackingMessage: json['trackingMessage'] as String?,
    );
  }
}

class WeeklyActivityBar {
  WeeklyActivityBar({
    required this.label,
    required this.steps,
    required this.distanceKm,
  });

  final String label;
  final int steps;
  final double distanceKm;

  factory WeeklyActivityBar.fromJson(Map<String, dynamic> json) {
    return WeeklyActivityBar(
      label: json['label'] as String? ?? 'Day',
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
    );
  }
}

class WeeklyChallengeModel {
  WeeklyChallengeModel({
    required this.title,
    required this.progress,
    required this.target,
    required this.rewardCoins,
    required this.unit,
    required this.completed,
  });

  final String title;
  final double progress;
  final double target;
  final int rewardCoins;
  final String unit;
  final bool completed;

  factory WeeklyChallengeModel.fromJson(Map<String, dynamic> json) {
    return WeeklyChallengeModel(
      title: json['title'] as String? ?? 'Challenge',
      progress: (json['progress'] as num? ?? 0).toDouble(),
      target: (json['target'] as num? ?? 0).toDouble(),
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      unit: json['unit'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class ActivityLeaderboardEntry {
  ActivityLeaderboardEntry({
    required this.displayName,
    required this.steps,
    required this.distanceKm,
    required this.rank,
  });

  final String displayName;
  final int steps;
  final double distanceKm;
  final String rank;

  factory ActivityLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLeaderboardEntry(
      displayName: json['displayName'] as String? ?? 'User',
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      rank: json['rank'] as String? ?? 'Bronze',
    );
  }
}

class DeviceActivitySnapshot {
  DeviceActivitySnapshot({
    required this.supported,
    required this.permissionGranted,
    required this.status,
    required this.source,
    required this.todayDateKey,
    required this.todaySteps,
    required this.distanceKm,
    required this.activeMinutes,
    required this.walkMinutes,
    required this.runMinutes,
    required this.calories,
    required this.weeklyHistory,
    this.message,
  });

  final bool supported;
  final bool permissionGranted;
  final String status;
  final String source;
  final String todayDateKey;
  final int todaySteps;
  final double distanceKm;
  final int activeMinutes;
  final int walkMinutes;
  final int runMinutes;
  final int calories;
  final String? message;
  final List<DeviceActivityDay> weeklyHistory;
}

class DeviceActivityDay {
  DeviceActivityDay({
    required this.dateKey,
    required this.label,
    required this.steps,
    required this.distanceKm,
    required this.activeMinutes,
    required this.walkMinutes,
    required this.runMinutes,
    required this.calories,
  });

  final String dateKey;
  final String label;
  final int steps;
  final double distanceKm;
  final int activeMinutes;
  final int walkMinutes;
  final int runMinutes;
  final int calories;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'label': label,
      'steps': steps,
      'distanceKm': distanceKm,
      'activeMinutes': activeMinutes,
      'walkMinutes': walkMinutes,
      'runMinutes': runMinutes,
      'calories': calories,
    };
  }

  factory DeviceActivityDay.fromJson(Map<String, dynamic> json) {
    return DeviceActivityDay(
      dateKey: json['dateKey'] as String,
      label: json['label'] as String,
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      activeMinutes: json['activeMinutes'] as int? ?? 0,
      walkMinutes: json['walkMinutes'] as int? ?? 0,
      runMinutes: json['runMinutes'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
    );
  }
}
