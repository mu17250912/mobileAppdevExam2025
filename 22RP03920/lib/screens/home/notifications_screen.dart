import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  Future<void> _markAsRead(String notificationId) async {
    await _firestoreService.notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> notifications) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in notifications) {
      if (!(doc['isRead'] as bool)) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment_approved':
        return Icons.check_circle_outline_rounded;
      case 'appointment_rejected':
        return Icons.highlight_off_rounded;
      case 'appointment_reminder':
        return Icons.alarm_rounded;
      case 'new_appointment_request':
        return Icons.add_alert_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final user = _authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see your notifications.')),
      );
    }

    FirebaseAnalytics.instance.logScreenView(screenName: 'NotificationsScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.feedback),
            tooltip: 'Send Feedback',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Feedback'),
                  content: Text('To report a notification issue, email support@smartcare.com or use the Contact Us option in the app drawer.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.notificationsCollection
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Error Loading Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final userNotifications = snapshot.data!.docs;
          final hasUnread = userNotifications.any((doc) => !(doc['isRead'] as bool));

          if (userNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if(hasUnread)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 20),
                    label: const Text('Mark all as read'),
                    onPressed: () => _markAllAsRead(userNotifications),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: userNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = userNotifications[index].data() as Map<String, dynamic>;
                    final notificationId = userNotifications[index].id;
                    final isRead = notification['isRead'] as bool? ?? false;
                    final type = notification['type'] as String? ?? '';
                    final icon = _getNotificationIcon(type);
                    final title = notification['title'] as String? ?? '';
                    final message = notification['message'] as String? ?? '';
                    final createdAtRaw = notification['createdAt'];
                    DateTime createdAt;
                    if (createdAtRaw is Timestamp) {
                      createdAt = createdAtRaw.toDate();
                    } else if (createdAtRaw is DateTime) {
                      createdAt = createdAtRaw;
                    } else {
                      createdAt = DateTime.now();
                    }

                    return Semantics(
                      label: 'Notification: $title. $message. ${isRead ? 'Read' : 'Unread'}.',
                      child: Card(
                      elevation: isRead ? 0.5 : 2.0,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isRead 
                            ? (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          width: isRead ? 1 : 1.5,
                        ),
                      ),
                      color: isRead 
                          ? (cardColor?.withOpacity(0.7) ?? Colors.grey[100])
                          : cardColor,
                      child: ListTile(
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notificationId);
                          }
                        },
                          leading: Semantics(
                            label: 'Notification type icon',
                            child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                            ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(message, style: TextStyle(color: textColor.withOpacity(0.8))),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 