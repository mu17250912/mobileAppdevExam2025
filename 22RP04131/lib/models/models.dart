import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType { invoice, quote, proforma, deliveryNote }

enum DocumentStatus {
  pending,
  paid,
  overdue,
  draft, // Added draft status
  cancelled, // Added cancelled status for consistency
}

class User {
  final String id;
  final String name;
  final String email;
  final String? businessName;
  final double defaultVATRate;
  final DateTime createdAt;
  final bool premium; // Added premium flag

  User({
    required this.id,
    required this.name,
    required this.email,
    this.businessName,
    this.defaultVATRate = 0.18,
    DateTime? createdAt,
    this.premium = false, // Default to false
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      businessName: json['businessName'],
      defaultVATRate: (json['defaultVATRate'] as num?)?.toDouble() ?? 0.18,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is DateTime)
              ? json['createdAt'] as DateTime
              : DateTime.now(),
      premium: json['premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'businessName': businessName,
        'defaultVATRate': defaultVATRate,
        'createdAt': createdAt,
        'premium': premium,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? businessName,
    double? defaultVATRate,
    DateTime? createdAt,
    bool? premium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      defaultVATRate: defaultVATRate ?? this.defaultVATRate,
      createdAt: createdAt ?? this.createdAt,
      premium: premium ?? this.premium,
    );
  }
}

class ClientInfo {
  final String name;
  final String? email;
  final String? phone;

  ClientInfo({
    required this.name,
    this.email,
    this.phone,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
      };

  ClientInfo copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return ClientInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class DocumentItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  DocumentItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'total': total,
      };

  DocumentItem copyWith({
    String? name,
    int? quantity,
    double? price,
    double? total,
  }) {
    return DocumentItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
    );
  }

  // Helper method to calculate total automatically
  static DocumentItem create({
    required String name,
    required int quantity,
    required double price,
  }) {
    return DocumentItem(
      name: name,
      quantity: quantity,
      price: price,
      total: quantity * price,
    );
  }
}

class Document {
  final String id;
  final DocumentType type;
  final String number;
  final ClientInfo clientInfo;
  final List<DocumentItem> items;
  final double subtotal;
  final double discount;
  final double vatRate;
  final double vatAmount;
  final double total;
  final DocumentStatus status;
  final DateTime createdDate;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String userId;

  Document({
    required this.id,
    required this.type,
    required this.number,
    required this.clientInfo,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    required this.status,
    required this.createdDate,
    DateTime? createdAt, // Made optional with default
    this.dueDate,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.toString() == 'DocumentType.' + (json['type'] ?? 'invoice'),
        orElse: () => DocumentType.invoice,
      ),
      number: json['number'] ?? '',
      clientInfo: ClientInfo.fromJson(json['clientInfo'] ?? {}),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DocumentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0.18,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString() == 'DocumentStatus.' + (json['status'] ?? 'pending'),
        orElse: () => DocumentStatus.pending,
      ),
      createdDate: (json['createdDate'] is Timestamp)
          ? (json['createdDate'] as Timestamp).toDate()
          : (json['createdDate'] is DateTime)
              ? json['createdDate'] as DateTime
              : DateTime.now(),
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is DateTime)
              ? json['createdAt'] as DateTime
              : DateTime.now(),
      dueDate: (json['dueDate'] is Timestamp)
          ? (json['dueDate'] as Timestamp).toDate()
          : (json['dueDate'] is DateTime)
              ? json['dueDate'] as DateTime
              : null,
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last,
        'number': number,
        'clientInfo': clientInfo.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'vatRate': vatRate,
        'vatAmount': vatAmount,
        'total': total,
        'status': status.toString().split('.').last,
        'createdDate': createdDate,
        'createdAt': createdAt,
        'dueDate': dueDate,
        'userId': userId,
      };

  Document copyWith({
    String? id,
    DocumentType? type,
    String? number,
    ClientInfo? clientInfo,
    List<DocumentItem>? items,
    double? subtotal,
    double? discount,
    double? vatRate,
    double? vatAmount,
    double? total,
    DocumentStatus? status,
    DateTime? createdDate,
    DateTime? createdAt,
    DateTime? dueDate,
    String? userId,
  }) {
    return Document(
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      clientInfo: clientInfo ?? this.clientInfo,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      userId: userId ?? this.userId,
    );
  }

  // Factory constructor for creating new documents
  factory Document.create({
    required DocumentType type,
    required String number,
    required ClientInfo clientInfo,
    required List<DocumentItem> items,
    required double subtotal,
    required double discount,
    required double vatRate,
    required double vatAmount,
    required double total,
    DocumentStatus status = DocumentStatus.draft,
    DateTime? createdDate,
    DateTime? dueDate,
    required String userId,
  }) {
    return Document(
      id: '', // Will be set when saving to database
      type: type,
      number: number,
      clientInfo: clientInfo,
      items: items,
      subtotal: subtotal,
      discount: discount,
      vatRate: vatRate,
      vatAmount: vatAmount,
      total: total,
      status: status,
      createdDate: createdDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      dueDate: dueDate,
      userId: userId,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status == DocumentStatus.pending;
  }

  bool get isPaid => status == DocumentStatus.paid;
  bool get isPending => status == DocumentStatus.pending;
  bool get isDraft => status == DocumentStatus.draft;

  String get statusText {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.paid:
        return 'Paid';
      case DocumentStatus.overdue:
        return 'Overdue';
      case DocumentStatus.draft:
        return 'Draft';
      case DocumentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeText {
    switch (type) {
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.quote:
        return 'Quote';
      case DocumentType.proforma:
        return 'Proforma';
      case DocumentType.deliveryNote:
        return 'Delivery Note';
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json, String id) {
    return NotificationItem(
      id: id,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: (json['timestamp'] is Timestamp)
          ? (json['timestamp'] as Timestamp).toDate()
          : (json['timestamp'] is DateTime)
              ? json['timestamp'] as DateTime
              : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'timestamp': timestamp,
        'read': read,
      };
}