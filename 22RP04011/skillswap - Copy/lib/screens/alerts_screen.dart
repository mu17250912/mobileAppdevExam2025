import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../services/app_service.dart';
import 'chat_screen.dart';
import 'schedule_session_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'session_requests_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  static int getUnreadCount(List<NotificationModel> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }

  int get unreadCount => _unreadCount;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _loadNotifications();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    final subscriptionStatus = data?['subscriptionStatus'] as String?;
    final subscriptionExpiry = data?['subscriptionExpiry'] as Timestamp?;
    bool hasActiveSubscription = false;
    if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
      final expiryDate = subscriptionExpiry.toDate();
      hasActiveSubscription = expiryDate.isAfter(DateTime.now());
    }
    if (!hasActiveSubscription && mounted) {
      Navigator.pushReplacementNamed(context, '/subscription');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final notifications =
            await AppService.getUserNotifications(user.uid, limit: 50);
        if (!mounted) return;
        setState(() {
          _notifications = notifications;
          _unreadCount = getUnreadCount(notifications);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await AppService.markAsRead(notification.id);
      // Update local state
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.markAsRead();
        }
        _unreadCount = getUnreadCount(_notifications);
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await AppService.markAllAsRead(user.uid);
        // Update local state
        if (!mounted) return;
        setState(() {
          _notifications = _notifications.map((n) => n.markAsRead()).toList();
          _unreadCount = getUnreadCount(_notifications);
        });
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.message:
        final senderId = notification.senderId;
        final senderName = notification.senderName ?? 'User';
        if (senderId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverId: senderId,
                receiverName: senderName,
              ),
            ),
          );
        }
        break;
      case NotificationType.sessionInvite:
      case NotificationType.sessionReminder:
        // Navigate to sessions list or show session details
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleSessionScreen(),
            ),
          );
        }
        break;
      case NotificationType.system:
        // Handle system notifications (like session responses)
        if (notification.data['sessionId'] != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SessionRequestsScreen(),
            ),
          );
        }
        break;
      case NotificationType.skillRequest:
        // Show action dialog for skill requests
        if (mounted) {
          _showSkillRequestActions(notification);
        }
        break;
      default:
        // Show notification details
        if (mounted) {
          _showNotificationDetails(notification);
        }
        break;
    }
  }

  void _showSkillRequestActions(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.typeIcon, color: notification.priorityColor),
            const SizedBox(width: 8),
            const Text('Skill Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'From: ${notification.senderName ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Received: ${notification.timeAgo}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          if (notification.senderId != null) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      receiverId: notification.senderId!,
                      receiverName: notification.senderName ?? 'User',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Message'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleSessionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.event),
              label: const Text('Schedule Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.typeIcon, color: notification.priorityColor),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Received: ${notification.timeAgo}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (notification.actionText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle action
              },
              child: Text(notification.actionText!),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text(
                          'You’ll see notifications here when you receive messages, session invites, or other updates.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48 : 8, vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Slidable(
                        key: ValueKey(notification.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _markAsRead(notification),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.done,
                              label: 'Read',
                            ),
                            SlidableAction(
                              onPressed: (_) async {
                                await AppService.deleteNotification(
                                    notification.id);
                                setState(() => _notifications.removeAt(index));
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: notification.isRead ? 1 : 3,
                          color: notification.isRead ? null : Colors.blue[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  notification.priorityColor.withOpacity(0.1),
                              child: Icon(notification.typeIcon,
                                  color: notification.priorityColor, size: 20),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: notification.isRead
                                    ? null
                                    : Colors.blue[800],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.preview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(notification.timeAgo,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500])),
                                    if (notification.priority ==
                                            NotificationPriority.high ||
                                        notification.priority ==
                                            NotificationPriority.urgent) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.priority_high,
                                          size: 12, color: Colors.orange),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: notification.isRead
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle)),
                            onTap: () => _handleNotificationTap(notification),
                            onLongPress: () =>
                                _showNotificationDetails(notification),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
