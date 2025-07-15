import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String imageUrl;
  final String buyerId;
  final String dealer;
  final String status;
  final Timestamp orderDate;

  Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.buyerId,
    required this.dealer,
    required this.status,
    required this.orderDate,
  });

  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    // Defensive: handle missing/null/wrong-type fields
    Timestamp safeTimestamp(dynamic value) {
      if (value is Timestamp) return value;
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return Timestamp.fromDate(dt);
      }
      return Timestamp.now();
    }
    double safeDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return Order(
      id: documentId,
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? '',
      price: safeDouble(data['price']),
      imageUrl: data['imageUrl']?.toString() ?? '',
      buyerId: data['buyerId']?.toString() ?? '',
      dealer: data['dealer']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      orderDate: safeTimestamp(data['orderDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'buyerId': buyerId,
      'dealer': dealer,
      'status': status,
      'orderDate': orderDate,
    };
  }
} 