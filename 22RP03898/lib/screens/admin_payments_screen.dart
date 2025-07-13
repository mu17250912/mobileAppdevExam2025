/// Admin Payments Management Screen for SafeRide
///
/// This screen provides admins with payment management capabilities:
/// - Verify pending payments
/// - Manage premium subscriptions
/// - Handle refund requests
/// - View payment analytics
/// - Monitor transaction history
///
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../models/booking_model.dart';
import '../utils/constants.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _premiumSubscriptions = [];
  List<Map<String, dynamic>> _refundRequests = [];
  List<Map<String, dynamic>> _transactionHistory = [];

  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  final List<String> _filterOptions = [
    'all',
    'pending',
    'verified',
    'failed',
    'refunded',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all payment-related data
      await Future.wait([
        _loadPendingPayments(),
        _loadPremiumSubscriptions(),
        _loadRefundRequests(),
        _loadTransactionHistory(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load payment data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingPayments() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('paymentStatus', isEqualTo: 'pending')
          .orderBy('bookingTime', descending: true)
          .limit(50)
          .get();

      _pendingPayments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _pendingPayments = [];
    }
  }

  Future<void> _loadPremiumSubscriptions() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isPremium', isEqualTo: true)
          .orderBy('premiumExpiry', descending: true)
          .limit(50)
          .get();

      _premiumSubscriptions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _premiumSubscriptions = [];
    }
  }

  Future<void> _loadRefundRequests() async {
    try {
      final snapshot = await _firestore
          .collection('refund_requests')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _refundRequests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _refundRequests = [];
    }
  }

  Future<void> _loadTransactionHistory() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _transactionHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _transactionHistory = [];
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
        title: const Text('Payment Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Premium'),
            Tab(text: 'Refunds'),
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
                    _buildPendingPaymentsTab(),
                    _buildPremiumSubscriptionsTab(),
                    _buildRefundRequestsTab(),
                    _buildTransactionHistoryTab(),
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
            onPressed: _loadPaymentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentsTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _pendingPayments.isEmpty
              ? _buildEmptyState('No pending payments found')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingPayments.length,
                  itemBuilder: (context, index) {
                    return _buildPendingPaymentCard(_pendingPayments[index]);
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

  Widget _buildPendingPaymentCard(Map<String, dynamic> payment) {
    final amount = payment['totalAmount']?.toDouble() ?? 0.0;
    final bookingTime = payment['bookingTime'] as Timestamp?;
    final passengerName = payment['passengerName'] ?? 'Unknown';
    final rideId = payment['rideId'] ?? '';

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
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.payment, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Pending',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Passenger: $passengerName',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'NGN ${NumberFormat('#,###').format(amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  bookingTime != null
                      ? _formatDateTime(bookingTime.toDate())
                      : 'Unknown time',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verifyPayment(payment),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Verify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
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

  Widget _buildPremiumSubscriptionsTab() {
    return _premiumSubscriptions.isEmpty
        ? _buildEmptyState('No premium subscriptions found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _premiumSubscriptions.length,
            itemBuilder: (context, index) {
              return _buildPremiumSubscriptionCard(
                  _premiumSubscriptions[index]);
            },
          );
  }

  Widget _buildPremiumSubscriptionCard(Map<String, dynamic> subscription) {
    final userName = subscription['name'] ?? 'Unknown';
    final email = subscription['email'] ?? '';
    final premiumExpiry = subscription['premiumExpiry'] as Timestamp?;
    final isActive = premiumExpiry?.toDate().isAfter(DateTime.now()) ?? false;

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
                  backgroundColor: Colors.amber.shade100,
                  child: Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        email,
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
                    color:
                        isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'EXPIRED',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
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
                  'Expires: ${premiumExpiry != null ? _formatDate(premiumExpiry.toDate()) : 'Unknown'}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (isActive)
                  Text(
                    '${_getDaysRemaining(premiumExpiry!.toDate())} days left',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _extendSubscription(subscription),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Extend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelSubscription(subscription),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
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

  Widget _buildRefundRequestsTab() {
    return _refundRequests.isEmpty
        ? _buildEmptyState('No refund requests found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _refundRequests.length,
            itemBuilder: (context, index) {
              return _buildRefundRequestCard(_refundRequests[index]);
            },
          );
  }

  Widget _buildRefundRequestCard(Map<String, dynamic> request) {
    final amount = request['amount']?.toDouble() ?? 0.0;
    final reason = request['reason'] ?? 'No reason provided';
    final status = request['status'] ?? 'pending';
    final createdAt = request['createdAt'] as Timestamp?;
    final userName = request['userName'] ?? 'Unknown';

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
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(Icons.money_off, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund Request',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'User: $userName',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'NGN ${NumberFormat('#,###').format(amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: $reason',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  createdAt != null
                      ? _formatDateTime(createdAt.toDate())
                      : 'Unknown time',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRefundStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getRefundStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approveRefund(request),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRefund(request),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistoryTab() {
    return _transactionHistory.isEmpty
        ? _buildEmptyState('No transaction history found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _transactionHistory.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(_transactionHistory[index]);
            },
          );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final type = transaction['type'] ?? 'unknown';
    final status = transaction['status'] ?? 'unknown';
    final timestamp = transaction['timestamp'] as Timestamp?;
    final description = transaction['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransactionTypeColor(type).withOpacity(0.1),
          child: Icon(
            _getTransactionTypeIcon(type),
            color: _getTransactionTypeColor(type),
            size: 20,
          ),
        ),
        title: Text(
          description.isNotEmpty ? description : type.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${type.toUpperCase()}'),
            if (timestamp != null)
              Text(
                _formatDateTime(timestamp.toDate()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'NGN ${NumberFormat('#,###').format(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTransactionStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _getTransactionStatusColor(status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRefundStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payment;
      case 'refund':
        return Icons.money_off;
      case 'subscription':
        return Icons.star;
      case 'commission':
        return Icons.percent;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Colors.green;
      case 'refund':
        return Colors.red;
      case 'subscription':
        return Colors.amber;
      case 'commission':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTransactionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _getDaysRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  Future<void> _verifyPayment(Map<String, dynamic> payment) async {
    try {
      await _firestore.collection('bookings').doc(payment['id']).update({
        'paymentStatus': 'paid',
        'verifiedAt': Timestamp.now(),
        'verifiedBy': 'admin',
      });

      // Add to transaction history
      await _firestore.collection('transactions').add({
        'type': 'payment',
        'amount': payment['totalAmount'],
        'status': 'completed',
        'description': 'Payment verified by admin',
        'bookingId': payment['id'],
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _pendingPayments.removeWhere((p) => p['id'] == payment['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verified successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify payment: $e')),
      );
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> payment) async {
    try {
      await _firestore.collection('bookings').doc(payment['id']).update({
        'paymentStatus': 'failed',
        'rejectedAt': Timestamp.now(),
        'rejectedBy': 'admin',
      });

      setState(() {
        _pendingPayments.removeWhere((p) => p['id'] == payment['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject payment: $e')),
      );
    }
  }

  Future<void> _extendSubscription(Map<String, dynamic> subscription) async {
    final daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Extend subscription for ${subscription['name']}'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              decoration: const InputDecoration(
                labelText: 'Number of days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              final days = int.tryParse(daysController.text);
              if (days != null && days > 0) {
                Navigator.pop(context);
                await _processSubscriptionExtension(subscription, days);
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubscriptionExtension(
      Map<String, dynamic> subscription, int days) async {
    try {
      final currentExpiry = subscription['premiumExpiry'] as Timestamp?;
      final newExpiry = currentExpiry != null
          ? currentExpiry.toDate().add(Duration(days: days))
          : DateTime.now().add(Duration(days: days));

      await _firestore.collection('users').doc(subscription['id']).update({
        'premiumExpiry': Timestamp.fromDate(newExpiry),
        'updatedAt': Timestamp.now(),
      });

      // Add to transaction history
      await _firestore.collection('transactions').add({
        'type': 'subscription',
        'amount': 0.0,
        'status': 'completed',
        'description': 'Subscription extended by $days days',
        'userId': subscription['id'],
        'timestamp': Timestamp.now(),
      });

      await _loadPremiumSubscriptions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription extended by $days days')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extend subscription: $e')),
      );
    }
  }

  Future<void> _cancelSubscription(Map<String, dynamic> subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel the premium subscription for ${subscription['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(subscription['id']).update({
        'isPremium': false,
        'premiumExpiry': null,
        'updatedAt': Timestamp.now(),
      });

      await _loadPremiumSubscriptions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel subscription: $e')),
      );
    }
  }

  Future<void> _approveRefund(Map<String, dynamic> request) async {
    try {
      await _firestore.collection('refund_requests').doc(request['id']).update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'approvedBy': 'admin',
      });

      // Add to transaction history
      await _firestore.collection('transactions').add({
        'type': 'refund',
        'amount': request['amount'],
        'status': 'completed',
        'description': 'Refund approved',
        'refundId': request['id'],
        'timestamp': Timestamp.now(),
      });

      setState(() {
        final index =
            _refundRequests.indexWhere((r) => r['id'] == request['id']);
        if (index != -1) {
          _refundRequests[index]['status'] = 'approved';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve refund: $e')),
      );
    }
  }

  Future<void> _rejectRefund(Map<String, dynamic> request) async {
    try {
      await _firestore.collection('refund_requests').doc(request['id']).update({
        'status': 'rejected',
        'rejectedAt': Timestamp.now(),
        'rejectedBy': 'admin',
      });

      setState(() {
        final index =
            _refundRequests.indexWhere((r) => r['id'] == request['id']);
        if (index != -1) {
          _refundRequests[index]['status'] = 'rejected';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject refund: $e')),
      );
    }
  }
}
