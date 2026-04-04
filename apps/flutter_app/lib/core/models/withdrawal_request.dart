class WithdrawalRequestModel {
  WithdrawalRequestModel({
    required this.id,
    required this.method,
    required this.destination,
    required this.coins,
    required this.status,
    required this.createdAt,
    required this.note,
  });

  final String id;
  final String method;
  final String destination;
  final int coins;
  final String status;
  final DateTime createdAt;
  final String? note;

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return WithdrawalRequestModel(
      id: json['id'] as String,
      method: json['method'] as String? ?? 'PAYPAL',
      destination: json['destination'] as String? ?? '',
      coins: json['coins'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING_ADMIN_REVIEW',
      createdAt:
          DateTime.parse((json['createdAt'] ?? json['requestedAt']) as String),
      note: json['note'] as String? ??
          (metadata is Map<String, dynamic>
              ? metadata['note'] as String?
              : null),
    );
  }
}
