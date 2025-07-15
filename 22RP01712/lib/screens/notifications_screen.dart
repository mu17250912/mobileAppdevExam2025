import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  final AppUser user;

  NotificationsScreen({required this.user});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

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
      final userNotifications = await NotificationService.getUserNotifications(widget.user.id);
      setState(() {
        notifications = userNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'status_update':
        return Icons.update;
      case 'admin_response':
        return Icons.admin_panel_settings;
      case 'application_deleted':
        return Icons.delete_forever;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'status_update':
        return Colors.blue;
      case 'admin_response':
        return Colors.orange;
      case 'application_deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'status_update':
        return 'Application Status Update';
      case 'admin_response':
        return 'Admin Response';
      case 'application_deleted':
        return 'Application Deleted';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Email warning banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.email, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📧 Please check your email carefully for detailed responses from employers.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You will see notifications here when admins respond to your applications',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final type = notification['type'] ?? 'notification';
                            final isRead = notification['isRead'] ?? false;
                            final createdAt = notification['createdAt'] as Timestamp?;
                            final date = createdAt?.toDate();

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: isRead ? 1 : 3,
                              color: isRead ? Colors.grey[50] : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getNotificationColor(type).withOpacity(0.1),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getNotificationTitle(type),
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      notification['jobTitle'] ?? 'Unknown Job',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      notification['message'] ?? '',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    if (date != null) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        '${date.toLocal().toString().split(' ')[0]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () async {
                                  // Mark as read
                                  if (!isRead) {
                                    await NotificationService.markNotificationAsRead(
                                      widget.user.id,
                                      notification['id'],
                                    );
                                    // Reload to update UI
                                    _loadNotifications();
                                  }

                                  // Show detailed notification
                                  _showNotificationDetails(notification);
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'notification';
    final jobTitle = notification['jobTitle'] ?? 'Unknown Job';
    final message = notification['message'] ?? '';
    final additionalData = notification['additionalData'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(type),
              color: _getNotificationColor(type),
            ),
            SizedBox(width: 8),
            Text(_getNotificationTitle(type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📧 Please check your email carefully for detailed responses from employers.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Job: $jobTitle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(message),
            if (additionalData != null && additionalData['adminNotes'] != null) ...[
              SizedBox(height: 16),
              Text(
                'Admin Response:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(additionalData['adminNotes']),
              ),
            ],
            if (additionalData != null && additionalData['status'] != null) ...[
              SizedBox(height: 16),
              Text(
                'Status: ${additionalData['status']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-applications');
            },
            child: Text('View Applications'),
          ),
        ],
      ),
    );
  }
} 