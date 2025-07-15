import 'package:flutter/material.dart';
import 'models/event.dart';
import 'services/event_service.dart';
import 'ticket_booking_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Events')),
      body: StreamBuilder<List<Event>>(
        stream: EventService().getEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No events available.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(event.date.toLocal().toString().split(' ')[0]),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TicketBookingScreen(event: event),
                    ),
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