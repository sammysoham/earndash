class AdminMetrics {
  AdminMetrics({
    required this.totalUsers,
    required this.dailyActiveUsers,
    required this.offerConversionRate,
    required this.withdrawalRate,
    required this.fraudRate,
    required this.averageLtvUsd,
    required this.revenuePerUserUsd,
  });

  final int totalUsers;
  final int dailyActiveUsers;
  final double offerConversionRate;
  final double withdrawalRate;
  final double fraudRate;
  final double averageLtvUsd;
  final double revenuePerUserUsd;

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      dailyActiveUsers: json['dailyActiveUsers'] as int? ?? 0,
      offerConversionRate: (json['offerConversionRate'] as num? ?? 0).toDouble(),
      withdrawalRate: (json['withdrawalRate'] as num? ?? 0).toDouble(),
      fraudRate: (json['fraudRate'] as num? ?? 0).toDouble(),
      averageLtvUsd: (json['averageLtvUsd'] as num? ?? 0).toDouble(),
      revenuePerUserUsd: (json['revenuePerUserUsd'] as num? ?? 0).toDouble(),
    );
  }
}
