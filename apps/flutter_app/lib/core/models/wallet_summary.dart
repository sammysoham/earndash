class WalletSummary {
  WalletSummary({
    required this.totalCoins,
    required this.pendingCoins,
    required this.withdrawableCoins,
    required this.lifetimeEarned,
    required this.transactionHistory,
  });

  final int totalCoins;
  final int pendingCoins;
  final int withdrawableCoins;
  final int lifetimeEarned;
  final List<WalletTransactionModel> transactionHistory;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final transactions = (json['transactionHistory'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return WalletSummary(
      totalCoins: json['totalCoins'] as int? ?? 0,
      pendingCoins: json['pendingCoins'] as int? ?? 0,
      withdrawableCoins: json['withdrawableCoins'] as int? ?? 0,
      lifetimeEarned: json['lifetimeEarned'] as int? ?? 0,
      transactionHistory: transactions,
    );
  }
}

class WalletTransactionModel {
  WalletTransactionModel({
    required this.type,
    required this.status,
    required this.coins,
    required this.referenceType,
    required this.createdAt,
  });

  final String type;
  final String status;
  final int coins;
  final String referenceType;
  final DateTime createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      type: json['type'] as String,
      status: json['status'] as String,
      coins: json['coins'] as int,
      referenceType: json['referenceType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
