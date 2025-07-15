import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .get();
    final Map<DateTime, List<String>> loadedEvents = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate();
      final title = data['title'] as String?;
      if (date != null && title != null) {
        final key = DateTime(date.year, date.month, date.day);
        loadedEvents.putIfAbsent(key, () => []).add(title);
      }
    }
    setState(() {
      _events.clear();
      _events.addAll(loadedEvents);
    });
  }

  Future<void> _addEventToFirebase(DateTime day, String event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .add({
      'date': Timestamp.fromDate(DateTime(day.year, day.month, day.day)),
      'title': event,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _addEvent(DateTime day, String event) {
    final key = DateTime(day.year, day.month, day.day);
    setState(() {
      if (_events.containsKey(key)) {
        _events[key]!.add(event);
      } else {
        _events[key] = [event];
      }
    });
    _addEventToFirebase(day, event);
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<String>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          if (_selectedDay != null)
            Expanded(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final controller = TextEditingController();
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add Event'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(hintText: 'Event name'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.trim().isNotEmpty) {
                        _addEvent(_selectedDay!, result.trim());
                      }
                    },
                    child: const Text('Add Event'),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: _getEventsForDay(_selectedDay!).asMap().entries.map((entry) {
                        final idx = entry.key;
                        final event = entry.value;
                        return ListTile(
                          title: Text(event),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) return;
                                  // Find the event doc to edit
                                  final snap = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('events')
                                      .where('date', isEqualTo: Timestamp.fromDate(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
                                      .where('title', isEqualTo: event)
                                      .get();
                                  if (snap.docs.isNotEmpty) {
                                    final docToEdit = snap.docs.first;
                                    final controller = TextEditingController(text: event);
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Edit Event'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(labelText: 'Event name'),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (result == true && controller.text.trim().isNotEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('events')
                                          .doc(docToEdit.id)
                                          .update({'title': controller.text.trim()});
                                      _loadEvents();
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) return;
                                  // Find the event doc to delete
                                  final snap = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('events')
                                      .where('date', isEqualTo: Timestamp.fromDate(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)))
                                      .where('title', isEqualTo: event)
                                      .get();
                                  for (final doc in snap.docs) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('events')
                                        .doc(doc.id)
                                        .delete();
                                  }
                                  _loadEvents();
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 