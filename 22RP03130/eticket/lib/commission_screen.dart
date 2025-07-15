import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/event.dart';
import 'models/ticket.dart';

class CommissionScreen extends StatelessWidget {
  const CommissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commission Dashboard')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('tickets').get(),
        builder: (context, ticketSnap) {
          if (!ticketSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = ticketSnap.data!.docs.map((doc) => Ticket.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('events').get(),
            builder: (context, eventSnap) {
              if (!eventSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = {for (var doc in eventSnap.data!.docs) doc.id: Event.fromMap(doc.id, doc.data() as Map<String, dynamic>)};
              double totalRevenue = 0;
              for (final ticket in tickets) {
                final event = events[ticket.eventId];
                if (event != null) {
                  totalRevenue += event.ticketPrice;
                }
              }
              final commissionRate = 0.10;
              final totalCommission = totalRevenue * commissionRate;
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Tickets Sold: ${tickets.length}', style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 16),
                    Text('Total Revenue: ${totalRevenue.toStringAsFixed(2)} RWF', style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 16),
                    Text('Total Commission (10%): ${totalCommission.toStringAsFixed(2)} RWF', style: const TextStyle(fontSize: 20, color: Colors.green)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 