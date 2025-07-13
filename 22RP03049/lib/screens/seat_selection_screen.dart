import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String busId;
  final dynamic busData;
  const SeatSelectionScreen({super.key, required this.busId, required this.busData});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int? selectedSeat;
  bool booking = false;
  String? bookingResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Bus')),
      body: const Center(
        child: Text('Seat selection is not required. Booking is handled directly from the bus list.'),
      ),
    );
  }
} 