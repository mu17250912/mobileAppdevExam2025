import 'package:cloud_firestore/cloud_firestore.dart';
import 'property.dart';

class Booking {
  final String id;
  final Property property;
  final String status; // e.g., 'Pending', 'Confirmed', 'Completed', 'Cancelled'
  final DateTime date;
  final String? message;
  final String? userId;
  final String? landlordId;

  Booking({
    required this.property,
    required this.status,
    required this.date,
    this.message,
    this.userId,
    this.landlordId,
  }) : id = 'BOOK_${DateTime.now().millisecondsSinceEpoch}';

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      property: Property.fromJson(json['property']),
      status: json['status'] ?? 'Pending',
      date: json['date'] != null 
          ? (json['date'] is Timestamp 
              ? (json['date'] as Timestamp).toDate()
              : DateTime.parse(json['date']))
          : DateTime.now(),
      message: json['message'],
      userId: json['userId'],
      landlordId: json['landlordId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property': property.toJson(),
      'status': status,
      'date': Timestamp.fromDate(date),
      'message': message,
      'userId': userId,
      'landlordId': landlordId,
    };
  }

  Booking copyWith({
    Property? property,
    String? status,
    DateTime? date,
    String? message,
    String? userId,
    String? landlordId,
  }) {
    return Booking(
      property: property ?? this.property,
      status: status ?? this.status,
      date: date ?? this.date,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      landlordId: landlordId ?? this.landlordId,
    );
  }
} 