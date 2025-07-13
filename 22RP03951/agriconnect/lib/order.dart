import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final String? shippingAddress;
  final String? phoneNumber;
  final String? paymentMethod;
  final bool isPaid;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.shippingAddress,
    this.phoneNumber,
    this.paymentMethod,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      shippingAddress: map['shippingAddress'],
      phoneNumber: map['phoneNumber'],
      paymentMethod: map['paymentMethod'],
      isPaid: map['isPaid'] ?? false,
    );
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    List<CartItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    String? shippingAddress,
    String? phoneNumber,
    String? paymentMethod,
    bool? isPaid,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
    );
  }
} 