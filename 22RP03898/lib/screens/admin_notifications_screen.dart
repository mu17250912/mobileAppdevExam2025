/// Admin Notifications Screen for SafeRide
///
/// This screen provides admins with notification management capabilities:
/// - Send push notifications to users
/// - Create notification templates
/// - Schedule notifications
/// - View notification history
/// - Manage notification settings
///
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _notificationHistory = [];
  List<Map<String, dynamic>> _notificationTemplates = [];
  List<UserModel> _allUsers = [];

  bool _isLoading = true;
  String? _error;
  String _selectedUserType = 'all';

  final List<String> _userTypeOptions = ['all', 'passenger', 'driver', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotificationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all notification-related data
      await Future.wait([
        _loadNotificationHistory(),
        _loadNotificationTemplates(),
        _loadAllUsers(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notification data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      _notificationHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _notificationHistory = [];
    }
  }

  Future<void> _loadNotificationTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('notification_templates')
          .orderBy('createdAt', descending: true)
          .get();

      _notificationTemplates = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _notificationTemplates = [];
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final users = await _adminService.getUsers(limit: 1000);
      _allUsers = users;
    } catch (e) {
      _allUsers = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Notification Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotificationData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send'),
            Tab(text: 'Templates'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSendNotificationTab(),
                    _buildTemplatesTab(),
                    _buildHistoryTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotificationData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickNotificationCard(),
          const SizedBox(height: 24),
          _buildCustomNotificationCard(),
          const SizedBox(height: 24),
          _buildBulkNotificationCard(),
        ],
      ),
    );
  }

  Widget _buildQuickNotificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickNotificationButton(
                    'System Maintenance',
                    'Scheduled maintenance notification',
                    Icons.build,
                    Colors.orange,
                    () => _sendQuickNotification('System Maintenance',
                        'Scheduled maintenance will begin in 30 minutes. Please save your work.'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickNotificationButton(
                    'New Feature',
                    'Announce new app features',
                    Icons.new_releases,
                    Colors.green,
                    () => _sendQuickNotification('New Feature Available',
                        'Check out our latest features! Update your app to get the best experience.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickNotificationButton(
                    'Emergency Alert',
                    'Send emergency notifications',
                    Icons.warning,
                    Colors.red,
                    () => _sendQuickNotification('Emergency Alert',
                        'Important safety information. Please check the app for details.'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickNotificationButton(
                    'Promotion',
                    'Send promotional offers',
                    Icons.local_offer,
                    Colors.purple,
                    () => _sendQuickNotification('Special Offer',
                        'Limited time offer! Get 20% off your next ride.'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNotificationButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNotificationCard() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                hintText: 'Enter notification title...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                hintText: 'Enter notification message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: const InputDecoration(
                      labelText: 'Target Users',
                      border: OutlineInputBorder(),
                    ),
                    items: _userTypeOptions.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        messageController.text.isNotEmpty) {
                      _sendCustomNotification(
                        titleController.text,
                        messageController.text,
                        _selectedUserType,
                      );
                      titleController.clear();
                      messageController.clear();
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkNotificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bulk Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBulkNotificationButton(
                    'All Users',
                    '${_allUsers.length} users',
                    Icons.people,
                    Colors.blue,
                    () => _showBulkNotificationDialog('all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBulkNotificationButton(
                    'Passengers Only',
                    '${_allUsers.where((u) => u.userType == UserType.passenger).length} users',
                    Icons.person,
                    Colors.green,
                    () => _showBulkNotificationDialog('passenger'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBulkNotificationButton(
                    'Drivers Only',
                    '${_allUsers.where((u) => u.userType == UserType.driver).length} users',
                    Icons.drive_eta,
                    Colors.orange,
                    () => _showBulkNotificationDialog('driver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBulkNotificationButton(
                    'Premium Users',
                    '${_allUsers.where((u) => u.isPremium == true).length} users',
                    Icons.star,
                    Colors.amber,
                    () => _showBulkNotificationDialog('premium'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkNotificationButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showCreateTemplateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _notificationTemplates.isEmpty
              ? _buildEmptyState('No notification templates found')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notificationTemplates.length,
                  itemBuilder: (context, index) {
                    return _buildTemplateCard(_notificationTemplates[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final title = template['title'] ?? '';
    final message = template['message'] ?? '';
    final category = template['category'] ?? 'general';
    final createdAt = template['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTemplateCategoryIcon(category),
                  color: _getTemplateCategoryColor(category),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'use':
                        _useTemplate(template);
                        break;
                      case 'edit':
                        _editTemplate(template);
                        break;
                      case 'delete':
                        _deleteTemplate(template);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'use',
                      child: Row(
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Use Template'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Template'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Template',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDateTime(createdAt.toDate())}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _notificationHistory.isEmpty
        ? _buildEmptyState('No notification history found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notificationHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(_notificationHistory[index]);
            },
          );
  }

  Widget _buildHistoryCard(Map<String, dynamic> notification) {
    final title = notification['title'] ?? '';
    final message = notification['message'] ?? '';
    final targetType = notification['targetType'] ?? 'all';
    final sentAt = notification['sentAt'] as Timestamp?;
    final sentCount = notification['sentCount'] ?? 0;
    final status = notification['status'] ?? 'sent';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationStatusColor(status).withOpacity(0.1),
          child: Icon(
            _getNotificationStatusIcon(status),
            color: _getNotificationStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Target: ${targetType.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Sent: $sentCount',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (sentAt != null)
              Text(
                _formatDateTime(sentAt.toDate()),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getNotificationStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _getNotificationStatusColor(status),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTemplateCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Icons.build;
      case 'feature':
        return Icons.new_releases;
      case 'emergency':
        return Icons.warning;
      case 'promotion':
        return Icons.local_offer;
      case 'update':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Color _getTemplateCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Colors.orange;
      case 'feature':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      case 'promotion':
        return Colors.purple;
      case 'update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendQuickNotification(String title, String message) async {
    try {
      await _sendNotificationToAllUsers(title, message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick notification sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  Future<void> _sendCustomNotification(
      String title, String message, String targetType) async {
    try {
      List<UserModel> targetUsers = [];

      switch (targetType) {
        case 'all':
          targetUsers = _allUsers;
          break;
        case 'passenger':
          targetUsers =
              _allUsers.where((u) => u.userType == UserType.passenger).toList();
          break;
        case 'driver':
          targetUsers =
              _allUsers.where((u) => u.userType == UserType.driver).toList();
          break;
        case 'admin':
          targetUsers =
              _allUsers.where((u) => u.userType == UserType.admin).toList();
          break;
      }

      await _sendNotificationToUsers(targetUsers, title, message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Notification sent to ${targetUsers.length} users')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  Future<void> _sendNotificationToAllUsers(String title, String message) async {
    await _sendNotificationToUsers(_allUsers, title, message);
  }

  Future<void> _sendNotificationToUsers(
      List<UserModel> users, String title, String message) async {
    int sentCount = 0;

    for (var user in users) {
      try {
        await _notificationService.sendNotificationToUser(
          userId: user.id,
          title: title,
          body: message,
        );
        sentCount++;
      } catch (e) {
        // Continue with other users even if one fails
      }
    }

    // Save to notification history
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'targetType': 'all',
      'sentCount': sentCount,
      'status': 'sent',
      'sentAt': Timestamp.now(),
      'sentBy': 'admin',
    });

    await _loadNotificationHistory();
  }

  void _showBulkNotificationDialog(String targetType) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send to ${targetType.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendCustomNotification(
                  titleController.text,
                  messageController.text,
                  targetType,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'general';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Template Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Template Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                'general',
                'maintenance',
                'feature',
                'emergency',
                'promotion',
                'update'
              ]
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                Navigator.pop(context);
                await _createTemplate(
                  titleController.text,
                  messageController.text,
                  selectedCategory,
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTemplate(
      String title, String message, String category) async {
    try {
      await _firestore.collection('notification_templates').add({
        'title': title,
        'message': message,
        'category': category,
        'createdAt': Timestamp.now(),
        'createdBy': 'admin',
      });

      await _loadNotificationTemplates();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create template: $e')),
      );
    }
  }

  void _useTemplate(Map<String, dynamic> template) {
    _sendCustomNotification(
      template['title'],
      template['message'],
      'all',
    );
  }

  void _editTemplate(Map<String, dynamic> template) {
    // Implementation for editing template
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit template functionality coming soon')),
    );
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore
          .collection('notification_templates')
          .doc(template['id'])
          .delete();
      await _loadNotificationTemplates();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete template: $e')),
      );
    }
  }
}
