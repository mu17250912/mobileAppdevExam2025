import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:infofarmer/screens/login_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<Map<dynamic, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final box = await Hive.openBox('notifications');
    final raw = box.values.toList();
    raw.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    setState(() {
      notifications = raw.cast<Map<dynamic, dynamic>>();
    });
  }

  Future<void> _markAsRead(int index) async {
    final box = Hive.box('notifications');
    final key = box.keyAt(index);
    final updated = Map<String, dynamic>.from(notifications[index]);
    updated['read'] = true;
    await box.put(key, updated);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['read'] == true;
                final date = DateTime.parse(notif['timestamp']).toString();
                return ListTile(
                  leading: Icon(
                    isRead ? Icons.notifications : Icons.fiber_new,
                    color: isRead ? Colors.grey : Colors.red,
                  ),
                  title: Text(
                    notif['title'] ?? '',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text('${notif['body'] ?? ''}\n$date'),
                  isThreeLine: true,
                  onTap: () => _markAsRead(index),
                );
              },
            ),
    );
  }
}