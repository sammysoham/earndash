class AdminUserSummary {
  AdminUserSummary({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.countryCode,
    required this.referralCode,
    required this.fraudScore,
    required this.totalCoins,
    required this.pendingCoins,
    required this.withdrawableCoins,
    required this.lifetimeEarned,
    required this.dailyStreak,
    required this.isBlocked,
    required this.isNewUser,
    required this.referredByDisplayName,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String role;
  final String countryCode;
  final String referralCode;
  final int fraudScore;
  final int totalCoins;
  final int pendingCoins;
  final int withdrawableCoins;
  final int lifetimeEarned;
  final int dailyStreak;
  final bool isBlocked;
  final bool isNewUser;
  final String? referredByDisplayName;
  final DateTime createdAt;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      countryCode: json['countryCode'] as String? ?? '--',
      referralCode: json['referralCode'] as String? ?? '',
      fraudScore: json['fraudScore'] as int? ?? 0,
      totalCoins: json['totalCoins'] as int? ?? 0,
      pendingCoins: json['pendingCoins'] as int? ?? 0,
      withdrawableCoins: json['withdrawableCoins'] as int? ?? 0,
      lifetimeEarned: json['lifetimeEarned'] as int? ?? 0,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isNewUser: json['isNewUser'] as bool? ?? false,
      referredByDisplayName: json['referredByDisplayName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminWithdrawalRequest {
  AdminWithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.method,
    required this.destination,
    required this.coins,
    required this.status,
    required this.requestedAt,
    required this.note,
  });

  final String id;
  final String userId;
  final String userDisplayName;
  final String method;
  final String destination;
  final int coins;
  final String status;
  final DateTime requestedAt;
  final String? note;

  factory AdminWithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return AdminWithdrawalRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String? ?? 'User',
      method: json['method'] as String? ?? 'PayPal',
      destination: json['destination'] as String? ?? '',
      coins: json['coins'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING_ADMIN_REVIEW',
      requestedAt: DateTime.parse(
        (json['requestedAt'] ?? json['createdAt']) as String,
      ),
      note: json['note'] as String? ??
          (json['metadata'] is Map<String, dynamic>
              ? (json['metadata'] as Map<String, dynamic>)['note'] as String?
              : null),
    );
  }
}
