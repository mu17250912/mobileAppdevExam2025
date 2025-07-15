import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'new_purchase_request',
                child: Text('New Requests'),
              ),
              const PopupMenuItem(
                value: 'payment_received',
                child: Text('Payments'),
              ),
              const PopupMenuItem(
                value: 'buyer_connected',
                child: Text('Connections'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];
          
          // Apply filter
          final filteredNotifications = _filterType == 'all'
              ? notifications
              : notifications.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['type'] == _filterType;
                }).toList();

          if (filteredNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _filterType == 'all' ? 'No notifications yet' : 'No ${_filterType.replaceAll('_', ' ')} notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index].data() as Map<String, dynamic>;
              final notificationId = filteredNotifications[index].id;
              final isRead = notification['isRead'] ?? false;
              final type = notification['type'] ?? '';
              final message = notification['message'] ?? '';
              final timestamp = notification['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
                child: ListTile(
                  leading: _buildNotificationIcon(type),
                  title: Text(
                    _getNotificationTitle(type),
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => _markAsRead(notificationId),
                        ),
                  onTap: () => _showNotificationDetails(notification),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'new_purchase_request':
        icon = Icons.receipt_long;
        color = AppColors.primary;
        break;
      case 'payment_received':
        icon = Icons.payment;
        color = AppColors.success;
        break;
      case 'buyer_connected':
        icon = Icons.connect_without_contact;
        color = AppColors.info;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'new_purchase_request':
        return 'New Purchase Request';
      case 'payment_received':
        return 'Payment Received';
      case 'buyer_connected':
        return 'Buyer Connected';
      default:
        return 'Notification';
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

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

  Future<void> _markAsRead(String notificationId) async {
    await NotificationService.markAsRead(notificationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as read'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final message = notification['message'] ?? '';
    final buyerName = notification['buyerName'] ?? '';
    final propertyTitle = notification['propertyTitle'] ?? '';
    final offer = notification['offer'] ?? '';
    final requestId = notification['requestId'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getNotificationTitle(type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AppTextStyles.body1),
            const SizedBox(height: 16),
            if (buyerName.isNotEmpty)
              _buildDetailRow('Buyer', buyerName),
            if (propertyTitle.isNotEmpty)
              _buildDetailRow('Property', propertyTitle),
            if (offer.isNotEmpty)
              _buildDetailRow('Offer', '\$$offer'),
            if (requestId.isNotEmpty)
              _buildDetailRow('Request ID', requestId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (requestId.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToRequest(requestId);
              },
              child: const Text('View Request'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRequest(String requestId) {
    // TODO: Navigate to the specific request in the commissioner dashboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to request: $requestId'),
        backgroundColor: AppColors.info,
      ),
    );
  }
} 