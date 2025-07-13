import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.notifications, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          if (notifications.any((n) => !n.read))
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'Mark all as read',
              onPressed: () => notificationProvider.markAllAsRead(),
            ),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no notifications at the moment.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => notificationProvider.removeNotification(n.id),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: n.read ? 1 : 3,
                    color: n.read ? colorScheme.surfaceVariant : colorScheme.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Icon(n.icon, color: colorScheme.primary),
                      ),
                      title: Text(
                        n.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: n.read ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        n.message,
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: colorScheme.primary),
                        onSelected: (value) {
                          if (value == 'mark_read') {
                            notificationProvider.markAsRead(n.id);
                          } else if (value == 'mark_unread') {
                            notificationProvider.markAsUnread(n.id);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!n.read)
                            PopupMenuItem(
                              value: 'mark_read',
                              child: Text('Mark as read', style: GoogleFonts.poppins()),
                            ),
                          if (n.read)
                            PopupMenuItem(
                              value: 'mark_unread',
                              child: Text('Mark as unread', style: GoogleFonts.poppins()),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 