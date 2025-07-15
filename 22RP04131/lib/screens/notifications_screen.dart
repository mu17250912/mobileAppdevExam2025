import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Notifications', style: AppTypography.titleMedium),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all as read
              final notifications = await appState.notificationsStream().first;
              for (final n in notifications.where((n) => !n.read)) {
                await appState.markNotificationRead(n.id);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: appState.notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final n = notifications[index];
              // Choose icon and color based on notification content/type
              IconData icon = Icons.notifications;
              Color iconColor = AppColors.primary;
              Color typeColor = AppColors.blue100;
              Color borderColor = AppColors.blue600;
              if (n.title.toLowerCase().contains('overdue')) {
                icon = Icons.warning;
                iconColor = AppColors.orange500;
                typeColor = AppColors.orange100;
                borderColor = AppColors.orange500;
              } else if (n.title.toLowerCase().contains('paid')) {
                icon = Icons.check_circle;
                iconColor = AppColors.success;
                typeColor = AppColors.green100;
                borderColor = AppColors.success;
              } else if (n.title.toLowerCase().contains('draft')) {
                icon = Icons.schedule;
                iconColor = AppColors.blue600;
                typeColor = AppColors.blue100;
                borderColor = AppColors.blue600;
              }
              return NotificationCard(
                typeColor: typeColor,
                borderColor: borderColor,
                icon: icon,
                iconColor: iconColor,
                title: n.title,
                message: n.message,
                time: _formatTimeAgo(n.timestamp),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class NotificationCard extends StatelessWidget {
  final Color typeColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;

  const NotificationCard({
    required this.typeColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: typeColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLarge),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text(time, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 