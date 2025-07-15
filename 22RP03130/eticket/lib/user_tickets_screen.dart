import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/ticket_service.dart';
import 'models/ticket.dart';
import 'models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTicketsScreen extends StatelessWidget {
  const UserTicketsScreen({super.key});

  Future<Event?> _fetchEvent(String eventId) async {
    final doc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromMap(doc.id, doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tickets')),
        body: const Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: StreamBuilder<List<Ticket>>(
        stream: TicketService().getUserTickets(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data!;
          if (tickets.isEmpty) {
            return const Center(child: Text('You have not bought any tickets.'));
          }
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return FutureBuilder<Event?>(
                future: _fetchEvent(ticket.eventId),
                builder: (context, eventSnap) {
                  if (!eventSnap.hasData) {
                    return const ListTile(title: Text('Loading event...'));
                  }
                  final event = eventSnap.data;
                  return ListTile(
                    title: Text(event?.title ?? 'Unknown Event'),
                    subtitle: Text('Purchased: \\${ticket.purchaseDate.toLocal()}\nType: \\${ticket.type == 'premium' ? 'Premium' : 'Standard'}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 