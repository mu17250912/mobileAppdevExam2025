import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class SnoozedNotificationsScreen extends StatefulWidget {
  const SnoozedNotificationsScreen({super.key});

  @override
  State<SnoozedNotificationsScreen> createState() =>
      _SnoozedNotificationsScreenState();
}

class _SnoozedNotificationsScreenState
    extends State<SnoozedNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // No longer mark all as read on open; user must mark individually
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snoozed Medications'),
        backgroundColor: Colors.blue, // Changed to blue
      ),
      backgroundColor: const Color(0xFFE6EDFF),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ReminderService().getAllUpcomingReminders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final snoozedReminders = snapshot.data!
              .where(
                (reminder) =>
                    reminder['status'] == 'snoozed' ||
                    reminder['status'] == 'read',
              )
              .toList();
          if (snoozedReminders.isEmpty) {
            return const Center(child: Text('No snoozed medications!'));
          }
          return ListView.builder(
            itemCount: snoozedReminders.length,
            itemBuilder: (context, index) {
              final reminder = snoozedReminders[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                  ),
                  title: Text(reminder['medName'] ?? 'No name'),
                  subtitle: Text(
                    'Snoozed until: \\${reminder['reminderTime']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!(reminder['read'] == true ||
                          reminder['status'] == 'read'))
                        IconButton(
                          icon: const Icon(Icons.done, color: Colors.green),
                          tooltip: 'Mark as read',
                          onPressed: () async {
                            final medId = reminder['medId'];
                            final reminderId = reminder['reminderId'];
                            if (medId != null && reminderId != null) {
                              await ReminderService().updateReminder(
                                medId,
                                reminderId,
                                {'read': true, 'status': 'read'},
                              );
                              setState(() {});
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete notification',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Notification'),
                              content: const Text(
                                'Are you sure you want to remove this notification from the list? (This will not delete the reminder itself.)',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final medId = reminder['medId'];
                            final reminderId = reminder['reminderId'];
                            if (medId != null && reminderId != null) {
                              await ReminderService().deleteReminder(
                                medId,
                                reminderId,
                              );
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
