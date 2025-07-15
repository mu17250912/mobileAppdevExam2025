import 'package:flutter/material.dart';
import 'models/event.dart';
import 'event_form_screen.dart';
import 'services/event_service.dart';

class OrganizerEventListScreen extends StatefulWidget {
  final String organizerId;
  const OrganizerEventListScreen({super.key, required this.organizerId});

  @override
  State<OrganizerEventListScreen> createState() => _OrganizerEventListScreenState();
}

class _OrganizerEventListScreenState extends State<OrganizerEventListScreen> {
  @override
  Widget build(BuildContext context) {
    // For now, fetch all events and filter by organizerId
    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: StreamBuilder<List<Event>>(
        stream: EventService().getEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!.where((e) => e.organizerId == widget.organizerId).toList();
          if (events.isEmpty) {
            return const Center(child: Text('No events created yet.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(event.date.toLocal().toString().split(' ')[0]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventFormScreen(event: event, organizerId: widget.organizerId),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text('Are you sure you want to delete this event?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await EventService().deleteEvent(event.id);
                        }
                      },
                    ),
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