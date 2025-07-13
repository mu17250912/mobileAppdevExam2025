import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  State<ProviderNotificationsScreen> createState() => _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState extends State<ProviderNotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String _filter = 'all'; // all, unread, read

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a provider.')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Stay updated with your business',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.filter_list_rounded,
                                color: Color(0xFF8B5CF6),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _FilterChip(
                                label: 'All',
                                selected: _filter == 'all',
                                onSelected: (selected) {
                                  setState(() {
                                    _filter = 'all';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FilterChip(
                                label: 'Unread',
                                selected: _filter == 'unread',
                                onSelected: (selected) {
                                  setState(() {
                                    _filter = 'unread';
                                  });
                                },
                                icon: Icons.mark_email_unread_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FilterChip(
                                label: 'Read',
                                selected: _filter == 'read',
                                onSelected: (selected) {
                                  setState(() {
                                    _filter = 'read';
                                  });
                                },
                                icon: Icons.mark_email_read_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Notifications List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        ),
                      );
                    }

                    final notifications = snapshot.data?.docs ?? [];
                    
                    // Filter notifications based on selected filter
                    final filteredNotifications = notifications.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final isRead = data['read'] == true;
                      
                      switch (_filter) {
                        case 'unread':
                          return !isRead;
                        case 'read':
                          return isRead;
                        default:
                          return true;
                      }
                    }).toList();

                    if (filteredNotifications.isEmpty) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                _filter == 'all' 
                                    ? Icons.notifications_none_rounded
                                    : _filter == 'unread' 
                                        ? Icons.mark_email_unread_outlined
                                        : Icons.mark_email_read_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filter == 'all' 
                                    ? 'No notifications yet'
                                    : _filter == 'unread' 
                                        ? 'No unread notifications'
                                        : 'No read notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filter == 'all' 
                                    ? 'You\'ll see notifications here when they arrive'
                                    : _filter == 'unread' 
                                        ? 'All caught up! No unread notifications'
                                        : 'No read notifications to show',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Notifications count header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_rounded,
                                    color: Color(0xFF8B5CF6),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${filteredNotifications.length} ${filteredNotifications.length == 1 ? 'Notification' : 'Notifications'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...filteredNotifications.map((doc) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final docId = doc.id;
                            final title = data['title'] ?? 'Notification';
                            final message = data['message'] ?? '';
                            final isRead = data['read'] == true;
                            final createdAt = data['createdAt'] as Timestamp?;
                            final type = data['type'] ?? 'general';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isRead ? Colors.grey[200]! : const Color(0xFF3B82F6).withOpacity(0.3),
                                  width: isRead ? 1 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 16,
                                    color: isRead ? const Color(0xFF374151) : const Color(0xFF1E293B),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getNotificationColor(type).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            type.toUpperCase(),
                                            style: TextStyle(
                                              color: _getNotificationColor(type),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (createdAt != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getTimeAgo(createdAt.toDate()),
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3B82F6),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () async {
                                  if (!isRead) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user!.uid)
                                        .collection('notifications')
                                        .doc(docId)
                                        .update({'read': true});
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return const Color(0xFF10B981);
      case 'payment':
        return const Color(0xFFF59E0B);
      case 'service_request':
        return const Color(0xFF8B5CF6);
      case 'premium_purchase':
        return const Color(0xFFEC4899);
      case 'subscription':
        return const Color(0xFF06B6D4);
      case 'message':
        return const Color(0xFF3B82F6);
      case 'rating':
        return const Color(0xFFF59E0B);
      case 'cancellation':
        return const Color(0xFFEF4444);
      case 'reschedule':
        return const Color(0xFF8B5CF6);
      case 'balance_added':
        return const Color(0xFF10B981);
      case 'profile_update':
        return const Color(0xFF6B7280);
      case 'new_user':
        return const Color(0xFF3B82F6);
      case 'system':
        return const Color(0xFF6B7280);
      case 'promotion':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.assignment_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'service_request':
        return Icons.build_rounded;
      case 'premium_purchase':
        return Icons.star_rounded;
      case 'subscription':
        return Icons.card_membership_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'rating':
        return Icons.star_rate_rounded;
      case 'cancellation':
        return Icons.cancel_rounded;
      case 'reschedule':
        return Icons.schedule_rounded;
      case 'balance_added':
        return Icons.account_balance_wallet_rounded;
      case 'profile_update':
        return Icons.person_rounded;
      case 'new_user':
        return Icons.person_add_rounded;
      case 'system':
        return Icons.settings_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF3B82F6),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF3B82F6),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
} 