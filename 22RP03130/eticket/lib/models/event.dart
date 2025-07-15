import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;
  final double ticketPrice;
  final double? premiumTicketPrice;
  final bool hasPremium;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
    required this.ticketPrice,
    this.premiumTicketPrice,
    this.hasPremium = false,
  });

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      organizerId: data['organizerId'] ?? '',
      ticketPrice: (data['ticketPrice'] as num).toDouble(),
      premiumTicketPrice: data['premiumTicketPrice'] != null ? (data['premiumTicketPrice'] as num).toDouble() : null,
      hasPremium: data['hasPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'organizerId': organizerId,
      'ticketPrice': ticketPrice,
      if (premiumTicketPrice != null) 'premiumTicketPrice': premiumTicketPrice,
      'hasPremium': hasPremium,
    };
  }
} 