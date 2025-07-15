/// Driver Earnings Screen for SafeRide
///
/// This screen shows drivers their earnings from commission-based monetization:
/// - Total earnings and pending amounts
/// - Commission breakdown by ride
/// - Payout history and requests
/// - Earnings analytics and trends
/// - Performance metrics
///
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/commission_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with TickerProviderStateMixin {
  final CommissionService _commissionService = CommissionService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  UserModel? _currentUser;
  DriverEarnings? _earnings;
  List<CommissionTransaction> _recentTransactions = [];
  List<Map<String, dynamic>> _payoutHistory = [];

  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '30d';

  final List<String> _periodOptions = ['7d', '30d', '90d', '1y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load current user
      _currentUser = await _authService.getCurrentUserModel();
      if (_currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load earnings data
      await Future.wait([
        _loadEarnings(),
        _loadRecentTransactions(),
        _loadPayoutHistory(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEarnings() async {
    _earnings = await _commissionService.getDriverEarnings(_currentUser!.id);
  }

  Future<void> _loadRecentTransactions() async {
    // Mock recent transactions - in real app, fetch from Firestore
    _recentTransactions = [
      CommissionTransaction(
        id: 'comm_1',
        bookingId: 'booking_1',
        driverId: _currentUser!.id,
        passengerId: 'passenger_1',
        bookingAmount: 5000.0,
        platformFee: 500.0,
        driverEarnings: 4500.0,
        currency: 'FRW',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        metadata: {
          'driverTier': 'premium',
          'commissionRate': 0.10,
          'bookingCompleted': true,
        },
      ),
      CommissionTransaction(
        id: 'comm_2',
        bookingId: 'booking_2',
        driverId: _currentUser!.id,
        passengerId: 'passenger_2',
        bookingAmount: 3000.0,
        platformFee: 300.0,
        driverEarnings: 2700.0,
        currency: 'FRW',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        metadata: {
          'driverTier': 'premium',
          'commissionRate': 0.10,
          'bookingCompleted': true,
        },
      ),
    ];
  }

  Future<void> _loadPayoutHistory() async {
    // Mock payout history - in real app, fetch from Firestore
    _payoutHistory = [
      {
        'id': 'payout_1',
        'amount': 10000.0,
        'status': 'completed',
        'paymentMethod': 'mtn_mobile_money',
        'requestedAt': DateTime.now().subtract(const Duration(days: 7)),
        'completedAt': DateTime.now().subtract(const Duration(days: 6)),
      },
      {
        'id': 'payout_2',
        'amount': 15000.0,
        'status': 'pending',
        'paymentMethod': 'airtel_money',
        'requestedAt': DateTime.now().subtract(const Duration(days: 2)),
        'completedAt': null,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Payouts'),
            Tab(text: 'Analytics'),
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
                    _buildOverviewTab(),
                    _buildTransactionsTab(),
                    _buildPayoutsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_earnings == null) {
      return const Center(child: Text('No earnings data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsCard(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildCommissionInfo(),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Earnings',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(_earnings!.totalEarnings)} FRW',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEarningsMetric(
                    'Pending',
                    _earnings!.pendingEarnings,
                    Colors.orange.shade100,
                    Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEarningsMetric(
                    'Paid Out',
                    _earnings!.paidEarnings,
                    Colors.white.withOpacity(0.2),
                    Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsMetric(
      String label, double amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Request Payout',
                    Icons.account_balance_wallet,
                    Colors.green,
                    _earnings!.pendingEarnings >= 5000.0
                        ? _requestPayout
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Transactions',
                    Icons.receipt,
                    Colors.blue,
                    () => _tabController.animateTo(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Payout History',
                    Icons.history,
                    Colors.orange,
                    () => _tabController.animateTo(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => _tabController.animateTo(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Rides',
                    '${_earnings!.totalRides}',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Completed Rides',
                    '${_earnings!.completedRides}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Earnings/Ride',
                    '${NumberFormat('#,###').format(_earnings!.averageEarningsPerRide)} FRW',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Completion Rate',
                    '${_earnings!.totalRides > 0 ? (_earnings!.completedRides / _earnings!.totalRides * 100).toStringAsFixed(1) : 0}%',
                    Icons.percent,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Structure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCommissionRateCard('Free Driver', '15%', Colors.grey),
            _buildCommissionRateCard('Basic Subscriber', '12%', Colors.blue),
            _buildCommissionRateCard('Premium Driver', '10%', Colors.green),
            _buildCommissionRateCard('Driver Premium', '8%', Colors.purple),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to a higher tier to reduce commission rates and earn more per ride!',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionRateCard(String tier, String rate, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tier,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return _recentTransactions.isEmpty
        ? _buildEmptyState('No transactions found')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recentTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(_recentTransactions[index]);
            },
          );
  }

  Widget _buildTransactionCard(CommissionTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${transaction.bookingId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(transaction.status),
                      fontSize: 10,
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
                  child: _buildTransactionMetric(
                    'Booking Amount',
                    '${NumberFormat('#,###').format(transaction.bookingAmount)} FRW',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTransactionMetric(
                    'Platform Fee',
                    '${NumberFormat('#,###').format(transaction.platformFee)} FRW',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTransactionMetric(
                    'Your Earnings',
                    '${NumberFormat('#,###').format(transaction.driverEarnings)} FRW',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Commission Rate: ${(transaction.metadata['commissionRate'] * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPayoutsTab() {
    return Column(
      children: [
        if (_earnings!.pendingEarnings >= 5000.0)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout Available!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You have ${NumberFormat('#,###').format(_earnings!.pendingEarnings)} FRW available for payout',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _requestPayout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Request Payout'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _payoutHistory.isEmpty
              ? _buildEmptyState('No payout history found')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payoutHistory.length,
                  itemBuilder: (context, index) {
                    return _buildPayoutCard(_payoutHistory[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    final status = payout['status'] as String;
    final amount = payout['amount'] as double;
    final paymentMethod = payout['paymentMethod'] as String;
    final requestedAt = payout['requestedAt'] as DateTime;
    final completedAt = payout['completedAt'] as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout #${payout['id'].substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(requestedAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
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
                      fontSize: 10,
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
                  child: _buildPayoutMetric(
                    'Amount',
                    '${NumberFormat('#,###').format(amount)} FRW',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPayoutMetric(
                    'Payment Method',
                    _getPaymentMethodDisplay(paymentMethod),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            if (completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${DateFormat('MMM dd, yyyy HH:mm').format(completedAt)}',
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

  Widget _buildPayoutMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodDisplay(String method) {
    switch (method) {
      case 'mtn_mobile_money':
        return 'MTN Mobile Money';
      case 'airtel_money':
        return 'Airtel Money';
      case 'mpesa':
        return 'M-Pesa';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsChart(),
          const SizedBox(height: 24),
          _buildPerformanceTrends(),
          const SizedBox(height: 24),
          _buildEarningsComparison(),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Earnings chart will be displayed here',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
                'Weekly Earnings', '+15%', Colors.green, Icons.trending_up),
            _buildTrendItem(
                'Ride Completion Rate', '+8%', Colors.blue, Icons.check_circle),
            _buildTrendItem(
                'Average Rating', '+0.2', Colors.orange, Icons.star),
            _buildTrendItem(
                'Commission Rate', '-2%', Colors.purple, Icons.percent),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonItem(
                'This Month', '125,000 FRW', 'Last Month', '98,000 FRW'),
            _buildComparisonItem(
                'This Week', '32,500 FRW', 'Last Week', '28,000 FRW'),
            _buildComparisonItem(
                'Today', '4,500 FRW', 'Yesterday', '3,800 FRW'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String currentLabel, String currentValue,
      String previousLabel, String previousValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  currentValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  previousLabel,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  previousValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPayout() async {
    if (_earnings!.pendingEarnings < 5000.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum payout amount is 5,000 FRW'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildPayoutDialog(),
    );

    if (result != null && result['confirmed'] == true) {
      try {
        final payoutResult = await _commissionService.requestPayout(
          driverId: _currentUser!.id,
          amount: result['amount'],
          paymentMethod: result['paymentMethod'],
        );

        if (payoutResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Payout request submitted: ${payoutResult['payoutId']}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payout request failed: ${payoutResult['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting payout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPayoutDialog() {
    final amountController = TextEditingController(
      text: _earnings!.pendingEarnings.toStringAsFixed(0),
    );
    String selectedPaymentMethod = 'mtn_mobile_money';

    return AlertDialog(
      title: const Text('Request Payout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (FRW)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: 'mtn_mobile_money', child: Text('MTN Mobile Money')),
              DropdownMenuItem(
                  value: 'airtel_money', child: Text('Airtel Money')),
              DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
              DropdownMenuItem(
                  value: 'bank_transfer', child: Text('Bank Transfer')),
            ],
            onChanged: (value) {
              selectedPaymentMethod = value!;
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
          onPressed: () {
            final amount = double.tryParse(amountController.text);
            if (amount != null &&
                amount >= 5000.0 &&
                amount <= _earnings!.pendingEarnings) {
              Navigator.pop(context, {
                'confirmed': true,
                'amount': amount,
                'paymentMethod': selectedPaymentMethod,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid amount (min: 5,000 FRW)'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Request Payout'),
        ),
      ],
    );
  }
}
