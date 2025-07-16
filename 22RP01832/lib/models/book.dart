import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final double price;
  final String description;
  final String subject;
  final String imageUrl;
  final String sellerId;
  final String status;
  final DateTime createdAt;
  final String? pdfUrl;
  final String? buyerId;

  Book({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.subject,
    required this.imageUrl,
    required this.sellerId,
    required this.status,
    required this.createdAt,
    this.pdfUrl,
    this.buyerId,
  });

  factory Book.fromMap(Map<String, dynamic> data, String documentId) {
    return Book(
      id: documentId,
      title: data['title'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0),

      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      pdfUrl: data['pdfUrl'],
      buyerId: data['buyerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'subject': subject,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'status': status,
      'createdAt': createdAt,
      'pdfUrl': pdfUrl,
      'buyerId': buyerId,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    double? price,
    String? description,
    String? subject,
    String? imageUrl,
    String? sellerId,
    String? status,
    DateTime? createdAt,
    String? pdfUrl,
    String? buyerId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      buyerId: buyerId ?? this.buyerId,
    );
  }
}
