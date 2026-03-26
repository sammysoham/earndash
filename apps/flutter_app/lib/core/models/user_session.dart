class SessionUser {
  SessionUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.referralCode,
    this.countryCode,
    this.fraudScore = 0,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String referralCode;
  final String? countryCode;
  final int fraudScore;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      referralCode: json['referralCode'] as String? ?? '',
      countryCode: json['countryCode'] as String?,
      fraudScore: json['fraudScore'] as int? ?? 0,
    );
  }
}

class UserSession {
  UserSession({required this.accessToken, required this.user});

  final String accessToken;
  final SessionUser user;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      accessToken: json['accessToken'] as String,
      user: SessionUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
