class ReferralOverview {
  ReferralOverview({
    required this.referralCode,
    required this.referredEarners,
    required this.commissionEarnedCoins,
    required this.abuseFlags,
    required this.activeReferrals,
    this.invitedByDisplayName,
  });

  final String referralCode;
  final int referredEarners;
  final int commissionEarnedCoins;
  final int abuseFlags;
  final List<ReferralEntry> activeReferrals;
  final String? invitedByDisplayName;

  factory ReferralOverview.fromJson(Map<String, dynamic> json) {
    return ReferralOverview(
      referralCode: json['referralCode'] as String? ?? '',
      referredEarners: json['referredEarners'] as int? ?? 0,
      commissionEarnedCoins: json['commissionEarnedCoins'] as int? ?? 0,
      abuseFlags: json['abuseFlags'] as int? ?? 0,
      activeReferrals: (json['activeReferrals'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => ReferralEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      invitedByDisplayName: json['invitedByDisplayName'] as String?,
    );
  }
}

class ReferralEntry {
  ReferralEntry({
    required this.displayName,
    required this.lifetimeEarnedCoins,
    required this.commissionCoins,
    required this.status,
  });

  final String displayName;
  final int lifetimeEarnedCoins;
  final int commissionCoins;
  final String status;

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    return ReferralEntry(
      displayName: json['displayName'] as String? ?? 'Friend',
      lifetimeEarnedCoins: json['lifetimeEarnedCoins'] as int? ?? 0,
      commissionCoins: json['commissionCoins'] as int? ?? 0,
      status: json['status'] as String? ?? 'Healthy',
    );
  }
}
