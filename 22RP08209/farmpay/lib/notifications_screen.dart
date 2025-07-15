import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'user_dashboard_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = SessionManager().userId;
      if (userId == null) return;

      final notificationsList = await _firebaseService.getUserNotifications(userId);
      setState(() {
        notifications = notificationsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firebaseService.markNotificationAsRead(notificationId);
      // Reload notifications to update the UI
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  String _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return '📦';
      case 'payment':
        return '💳';
      case 'payment_received':
        return '💰';
      case 'delivery':
        return '🚚';
      default:
        return '📢';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'payment_received':
        return Colors.orange;
      case 'delivery':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You\'ll see notifications here when you have updates',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final type = notification['type'] ?? 'general';
                    final message = notification['message'] ?? 'No message';
                    final status = notification['status'] ?? 'unread';
                    final createdAt = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();
                    final isUnread = status == 'unread';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isUnread ? Colors.blue.withOpacity(0.1) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotificationColor(type),
                          child: Text(
                            _getNotificationIcon(type),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          message,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isUnread
                            ? IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => _markAsRead(notification['id']),
                                tooltip: 'Mark as read',
                              )
                            : null,
                        onTap: isUnread ? () => _markAsRead(notification['id']) : null,
                      ),
                    );
                  },
                ),
    );
  }
} 