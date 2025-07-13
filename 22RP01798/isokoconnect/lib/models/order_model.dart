class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String? buyerMomoAccount;
  final String sellerId;
  final String sellerName;
  final double quantity;
  final double pricePerKg;
  final double totalAmount;
  final double commission; // 5.3% commission
  final double payout; // Seller payout (totalAmount - commission)
  final String status; // 'pending', 'accepted', 'rejected'
  final String paymentStatus; // 'pending', 'paid'
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerMomoAccount,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.commission, // 5.3% commission
    required this.payout, // Seller payout
    required this.status,
    required this.paymentStatus,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerMomoAccount': buyerMomoAccount,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'commission': commission, // 5.3% commission
      'payout': payout, // Seller payout
      'status': status,
      'paymentStatus': paymentStatus,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      buyerMomoAccount: map['buyerMomoAccount'],
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      commission: (map['commission'] ?? 0).toDouble(), // 5.3% commission
      payout: (map['payout'] ?? 0).toDouble(), // Seller payout
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerMomoAccount,
    String? sellerId,
    String? sellerName,
    double? quantity,
    double? pricePerKg,
    double? totalAmount,
    double? commission, // 5.3% commission
    double? payout, // Seller payout
    String? status,
    String? paymentStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerMomoAccount: buyerMomoAccount ?? this.buyerMomoAccount,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      commission: commission ?? this.commission, // 5.3% commission
      payout: payout ?? this.payout, // Seller payout
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 