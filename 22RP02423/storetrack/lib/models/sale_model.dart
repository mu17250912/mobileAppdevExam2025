import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      total: (map['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

class SaleModel {
  final String id;
  final List<SaleItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String cashierId;
  final String cashierName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final DateTime createdAt;
  final String paymentMethod;
  final double amountReceived;
  final double change;
  final String status; // 'completed', 'pending', 'cancelled'

  SaleModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.cashierId,
    required this.cashierName,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    required this.createdAt,
    this.paymentMethod = 'cash',
    this.amountReceived = 0.0,
    this.change = 0.0,
    this.status = 'completed',
  });

  factory SaleModel.fromMap(Map<String, dynamic> map, String id) {
    return SaleModel(
      id: id,
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => SaleItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      cashierId: map['cashierId'] ?? '',
      cashierName: map['cashierName'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      amountReceived: (map['amountReceived'] ?? 0.0).toDouble(),
      change: (map['change'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'createdAt': createdAt,
      'paymentMethod': paymentMethod,
      'amountReceived': amountReceived,
      'change': change,
      'status': status,
    };
  }

  SaleModel copyWith({
    String? id,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? cashierId,
    String? cashierName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? createdAt,
    String? paymentMethod,
    double? amountReceived,
    double? change,
    String? status,
  }) {
    return SaleModel(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      change: change ?? this.change,
      status: status ?? this.status,
    );
  }
} 