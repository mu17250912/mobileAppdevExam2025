import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllNotifications());
  }

  void _loadAllNotifications() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.loadAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                // TODO: Implement mark all as read
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notificationProvider.notifications.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final isMine = notification.userId == authProvider.currentUser?.uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isMine ? const Color(0xFFEDF7ED) : null,
                child: ListTile(
                  leading: Icon(
                    notification.read ? Icons.notifications : Icons.notifications_active,
                    color: isMine
                        ? const Color(AppColors.successColor)
                        : (notification.read ? Colors.grey : const Color(AppColors.primaryColor)),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMine ? const Color(AppColors.successColor) : null,
                    ),
                  ),
                  subtitle: Text(
                    '${notification.message}\n${notification.createdAt.toLocal().toString().split(".")[0]}',
                  ),
                  trailing: isMine ? const Icon(Icons.person, color: Color(AppColors.successColor)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 