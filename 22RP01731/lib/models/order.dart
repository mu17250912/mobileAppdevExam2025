import 'cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status;
  final String address;
  final String phone;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
    required this.address,
    required this.phone,
  });

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>).map((item) => CartItem.fromMap(item as Map<String, dynamic>)).toList(),
      total: (map['total'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'date': Timestamp.fromDate(date),
      'status': status,
      'address': address,
      'phone': phone,
    };
  }
} 