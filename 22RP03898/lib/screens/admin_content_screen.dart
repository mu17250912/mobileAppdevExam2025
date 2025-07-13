/// Admin Content Moderation Screen for SafeRide
///
/// This screen provides admins with content moderation capabilities:
/// - Review and moderate ride posts
/// - Handle user reports
/// - Remove inappropriate content
/// - Manage content guidelines
/// - View moderation history
///
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  List<RideModel> _reportedRides = [];
  List<Map<String, dynamic>> _userReports = [];
  List<Map<String, dynamic>> _moderationHistory = [];

  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  final List<String> _filterOptions = [
    'all',
    'pending',
    'reviewed',
    'removed',
    'approved',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContentData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load reported rides
      final reportedRides = await _loadReportedRides();

      // Load user reports
      final userReports = await _loadUserReports();

      // Load moderation history
      final moderationHistory = await _loadModerationHistory();

      if (mounted) {
        setState(() {
          _reportedRides = reportedRides;
          _userReports = userReports;
          _moderationHistory = moderationHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load content data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<RideModel>> _loadReportedRides() async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => RideModel.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadModerationHistory() async {
    try {
      final snapshot = await _firestore
          .collection('moderation_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
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
        title: const Text('Content Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContentData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reported Rides'),
            Tab(text: 'User Reports'),
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
                    _buildReportedRidesTab(),
                    _buildUserReportsTab(),
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
            onPressed: _loadContentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedRidesTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _reportedRides.isEmpty
              ? _buildEmptyState('No reported rides found')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reportedRides.length,
                  itemBuilder: (context, index) {
                    return _buildReportedRideCard(_reportedRides[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.red.shade100,
                checkmarkColor: Colors.red,
              ),
            );
          }).toList(),
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

  Widget _buildReportedRideCard(RideModel ride) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.drive_eta, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.origin.name} → ${ride.destination.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Driver: ${ride.driverName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ride.reportCount ?? 0} reports',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(ride.departureTime),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatTime(ride.departureTime),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  'NGN ${ride.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reviewRide(ride),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeRide(ride),
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserReportsTab() {
    return _userReports.isEmpty
        ? _buildEmptyState('No user reports found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userReports.length,
            itemBuilder: (context, index) {
              return _buildUserReportCard(_userReports[index]);
            },
          );
  }

  Widget _buildUserReportCard(Map<String, dynamic> report) {
    final reportType = report['type'] ?? 'unknown';
    final status = report['status'] ?? 'pending';
    final createdAt = report['createdAt'] as Timestamp?;

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
                  _getReportTypeIcon(reportType),
                  color: _getReportTypeColor(reportType),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportType.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Reported by: ${report['reporterName'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (report['description'] != null) ...[
              Text(
                'Description:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                report['description'],
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (createdAt != null) ...[
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(createdAt.toDate()),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
                const Spacer(),
                if (status == 'pending') ...[
                  OutlinedButton(
                    onPressed: () => _handleReport(report, 'approved'),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _handleReport(report, 'rejected'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _moderationHistory.isEmpty
        ? _buildEmptyState('No moderation history found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _moderationHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(_moderationHistory[index]);
            },
          );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final action = history['action'] ?? 'unknown';
    final timestamp = history['timestamp'] as Timestamp?;
    final moderator = history['moderatorName'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(action).withOpacity(0.1),
          child: Icon(
            _getActionIcon(action),
            color: _getActionColor(action),
            size: 20,
          ),
        ),
        title: Text(
          '${action.toUpperCase()} - ${history['contentType'] ?? 'content'}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moderated by: $moderator'),
            if (timestamp != null)
              Text(
                _formatDateTime(timestamp.toDate()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getActionColor(action).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            action.toUpperCase(),
            style: TextStyle(
              color: _getActionColor(action),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getReportTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'inappropriate':
        return Icons.block;
      case 'spam':
        return Icons.report;
      case 'fake':
        return Icons.warning;
      case 'harassment':
        return Icons.person_off;
      default:
        return Icons.flag;
    }
  }

  Color _getReportTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'inappropriate':
        return Colors.red;
      case 'spam':
        return Colors.orange;
      case 'fake':
        return Colors.yellow.shade700;
      case 'harassment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'reviewed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'remove':
        return Icons.delete;
      case 'approve':
        return Icons.check_circle;
      case 'warn':
        return Icons.warning;
      case 'ban':
        return Icons.block;
      default:
        return Icons.edit;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'remove':
        return Colors.red;
      case 'approve':
        return Colors.green;
      case 'warn':
        return Colors.orange;
      case 'ban':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _reviewRide(RideModel ride) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${ride.origin.name} → ${ride.destination.name}'),
            Text('Driver: ${ride.driverName}'),
            Text('Date: ${_formatDate(ride.departureTime)}'),
            Text('Time: ${_formatTime(ride.departureTime)}'),
            Text('Fare: NGN ${ride.fare.toStringAsFixed(0)}'),
            Text('Reports: ${ride.reportCount ?? 0}'),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do with this ride?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveRide(ride);
            },
            child: const Text('Approve'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeRide(ride);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRide(RideModel ride) async {
    try {
      await _firestore.collection('rides').doc(ride.id).update({
        'reportCount': 0,
        'moderated': true,
        'moderatedAt': Timestamp.now(),
        'moderatedBy': 'admin',
      });

      // Add to moderation history
      await _firestore.collection('moderation_history').add({
        'action': 'approve',
        'contentType': 'ride',
        'contentId': ride.id,
        'moderatorName': 'Admin',
        'timestamp': Timestamp.now(),
        'details': 'Ride approved after review',
      });

      setState(() {
        _reportedRides.removeWhere((r) => r.id == ride.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve ride: $e')),
      );
    }
  }

  Future<void> _removeRide(RideModel ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Ride'),
        content: Text(
          'Are you sure you want to remove this ride? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.cancelRide(ride.id);

      // Add to moderation history
      await _firestore.collection('moderation_history').add({
        'action': 'remove',
        'contentType': 'ride',
        'contentId': ride.id,
        'moderatorName': 'Admin',
        'timestamp': Timestamp.now(),
        'details': 'Ride removed due to reports',
      });

      setState(() {
        _reportedRides.removeWhere((r) => r.id == ride.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove ride: $e')),
      );
    }
  }

  Future<void> _handleReport(Map<String, dynamic> report, String action) async {
    try {
      await _firestore.collection('reports').doc(report['id']).update({
        'status': action,
        'handledAt': Timestamp.now(),
        'handledBy': 'admin',
      });

      // Add to moderation history
      await _firestore.collection('moderation_history').add({
        'action': action,
        'contentType': 'report',
        'contentId': report['id'],
        'moderatorName': 'Admin',
        'timestamp': Timestamp.now(),
        'details': 'Report ${action}',
      });

      setState(() {
        final index = _userReports.indexWhere((r) => r['id'] == report['id']);
        if (index != -1) {
          _userReports[index]['status'] = action;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report ${action} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to handle report: $e')),
      );
    }
  }
}
