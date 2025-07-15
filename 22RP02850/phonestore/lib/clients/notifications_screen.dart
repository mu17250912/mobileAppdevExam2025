import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../clients/client_home.dart';
import '../clients/order_history_screen.dart';
import '../clients/cart_page.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const String kStoreName = 'Your Store Name';
const String kLogoUrl = 'assets/phonestorelogo.jpg';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please login to view notifications'));
    }
    return _buildNotificationsContent(context, user);
  }

  Widget _buildNotificationsContent(BuildContext context, User user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalPadding = constraints.maxWidth > 600 ? 48 : 12;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading notifications'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.notifications, color: kPrimaryColor),
                  title: Text(data['title'] ?? 'Notification'),
                  subtitle: Text(data['body'] ?? ''),
                  trailing: data['read'] == false
                      ? const Icon(Icons.circle, color: Colors.red, size: 12)
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_update':
        return Colors.orange;
      case 'new_product':
        return Colors.green;
      case 'promotion':
        return Colors.purple;
      default:
        return kPrimaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_update':
        return Icons.shopping_bag;
      case 'new_product':
        return Icons.new_releases;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  void _handleNotificationTap(BuildContext context, String type, Map<String, dynamic> data) {
    // Navigate based on notification type
    switch (type) {
      case 'order_update':
        // Navigate to order history
        Navigator.pushNamed(context, '/order_history');
        break;
      case 'new_product':
        // Navigate to home
        Navigator.pushNamed(context, '/client_home');
        break;
      case 'promotion':
        // Navigate to promotions (if you have a promotions screen)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion details coming soon!')),
        );
        break;
    }
  }
} 