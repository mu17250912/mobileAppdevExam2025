class PaymentModel {
  final String id;
  final String userId;
  final String? eventId;
  final double amount;
  final String currency;
  final String status;
  final String method;
  final String fullName;
  final String telephone;
  final double charges;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.userId,
    this.eventId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    required this.fullName,
    required this.telephone,
    required this.charges,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      eventId: json['eventId'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RWF',
      status: json['status'] ?? 'pending',
      method: json['method'] ?? '',
      fullName: json['fullName'] ?? '',
      telephone: json['telephone'] ?? '',
      charges: (json['charges'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'fullName': fullName,
      'telephone': telephone,
      'charges': charges,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 