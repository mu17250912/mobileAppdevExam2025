import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Ticket {
  final String id;
  final String eventId;
  final String userId;
  final DateTime purchaseDate;
  final String type; // 'standard' or 'premium'

  Ticket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.purchaseDate,
    this.type = 'standard',
  });

  factory Ticket.fromMap(String id, Map<String, dynamic> data) {
    return Ticket(
      id: id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      type: data['type'] ?? 'standard',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'purchaseDate': purchaseDate,
      'type': type,
    };
  }
} 