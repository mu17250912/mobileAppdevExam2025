import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/user_store.dart';
import 'delivery_confirmation_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String? _userName;
  String? _userRole;
  List<NotificationModel> _notifications = [];
  List<Map<String, dynamic>> _firestoreNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserStore.getCurrentUser();
    setState(() {
      _userName = user?.name;
      _userRole = user?.role;
    });
    // Load notifications after user data is available
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_userName == null || _userRole == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('employeeEmail', isEqualTo: _userName)
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      _firestoreNotifications = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _markAllAsRead() {
    NotificationStore.markAllRead();
    setState(() {
      _notifications = NotificationStore.getNotificationsForUser(_userRole, _userName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              NotificationStore.clearForUser(_userRole, _userName);
              setState(() {
                _notifications = NotificationStore.getNotificationsForUser(_userRole, _userName);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    notification.read = true;
    setState(() {});

    // Handle different notification types
    if (notification.type == 'delivery_completed' && _userRole == 'Employee') {
      // Find the corresponding request
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('requests')
            .where('subject', isEqualTo: notification.requestSubject)
            .where('employeeName', isEqualTo: _userName)
            .where('status', isEqualTo: 'Delivered')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final requestData = snapshot.docs.first.data();
          final request = Request.fromFirestore(requestData, snapshot.docs.first.id);
          
          if (!mounted) return;
          
          // Navigate to delivery confirmation screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryConfirmationScreen(request: request),
            ),
          );
          
          // Refresh notifications if delivery was confirmed
          if (result == true) {
            _loadNotifications();
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request not found or already confirmed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'request_approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'request_rejected':
      case 'request_rejected_by_approver':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'request_forwarded':
        return const Icon(Icons.forward, color: Colors.blue);
      case 'delivery_completed':
        return const Icon(Icons.local_shipping, color: Colors.orange);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('NotificationCenterScreen build called');
    final notifications = _firestoreNotifications.isNotEmpty ? _firestoreNotifications : _notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all notifications',
              onPressed: _clearAllNotifications,
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                
                // Handle both Firestore notifications (Map) and local notifications (NotificationModel)
                String type;
                String title;
                String message;
                DateTime timestamp;
                bool read;
                
                if (notification is Map<String, dynamic>) {
                  // Firestore notification
                  type = notification['type'] ?? '';
                  title = notification['title'] ?? '';
                  message = notification['message'] ?? '';
                  timestamp = (notification['timestamp'] as Timestamp).toDate();
                  read = notification['read'] ?? false;
                } else if (notification is NotificationModel) {
                  // Local notification (NotificationModel)
                  type = notification.type;
                  title = notification.title;
                  message = notification.message;
                  timestamp = notification.timestamp;
                  read = notification.read;
                } else {
                  // Fallback for unknown types
                  type = '';
                  title = 'Unknown notification';
                  message = 'Unknown notification type';
                  timestamp = DateTime.now();
                  read = false;
                }
                
                final isDeliveryNotification = type == 'delivery_completed' && _userRole == 'Employee';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: _getNotificationIcon(type),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (isDeliveryNotification && !read)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Tap to confirm delivery',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: read
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      if (notification is Map<String, dynamic>) {
                        // Convert Firestore notification to NotificationModel for handling
                        final notificationModel = NotificationModel(
                          title: title,
                          message: message,
                          type: type,
                          timestamp: timestamp,
                          read: read,
                          targetRole: notification['targetRole'] ?? '',
                          targetUser: notification['targetUser'] ?? '',
                          requestSubject: notification['requestSubject'] ?? '',
                        );
                        _handleNotificationTap(notificationModel);
                      } else {
                        _handleNotificationTap(notification as NotificationModel);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 