class OfferModel {
  OfferModel({
    required this.provider,
    required this.externalOfferId,
    required this.title,
    required this.description,
    required this.payoutCoins,
    required this.ctaUrl,
    required this.iconUrl,
    required this.estimatedMinutes,
  });

  final String provider;
  final String externalOfferId;
  final String title;
  final String description;
  final int payoutCoins;
  final String ctaUrl;
  final String iconUrl;
  final int estimatedMinutes;

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      provider: json['provider'] as String,
      externalOfferId: json['externalOfferId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      payoutCoins: json['payoutCoins'] as int,
      ctaUrl: json['ctaUrl'] as String,
      iconUrl: json['iconUrl'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
    );
  }
}
