/// Monetization Dashboard Screen for SafeRide
///
/// This screen provides a comprehensive view of all monetization features:
/// - Subscription management
/// - In-app purchases
/// - Commission tracking
/// - Ad revenue
/// - Payment analytics
/// - Revenue optimization
///
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';
import '../services/commission_service.dart';
import '../services/payment_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class MonetizationDashboardScreen extends StatefulWidget {
  const MonetizationDashboardScreen({super.key});

  @override
  State<MonetizationDashboardScreen> createState() =>
      _MonetizationDashboardScreenState();
}

class _MonetizationDashboardScreenState
    extends State<MonetizationDashboardScreen> with TickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CommissionService _commissionService = CommissionService();
  final PaymentService _paymentService = PaymentService();
  final AdService _adService = AdService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  UserModel? _currentUser;

  // Analytics data
  Map<String, dynamic> _subscriptionAnalytics = {};
  Map<String, dynamic> _commissionAnalytics = {};
  Map<String, dynamic> _paymentAnalytics = {};
  Map<String, dynamic> _adAnalytics = {};

  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '30d';

  final List<String> _periodOptions = ['7d', '30d', '90d', '1y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

      // Load analytics data
      await Future.wait([
        _loadSubscriptionAnalytics(),
        _loadCommissionAnalytics(),
        _loadPaymentAnalytics(),
        _loadAdAnalytics(),
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

  Future<void> _loadSubscriptionAnalytics() async {
    _subscriptionAnalytics =
        await _subscriptionService.getSubscriptionAnalytics();
  }

  Future<void> _loadCommissionAnalytics() async {
    final days = _getDaysFromPeriod(_selectedPeriod);
    final startDate = DateTime.now().subtract(Duration(days: days));
    _commissionAnalytics = await _commissionService.getPlatformRevenueAnalytics(
      startDate: startDate,
      endDate: DateTime.now(),
    );
  }

  Future<void> _loadPaymentAnalytics() async {
    // Mock payment analytics data
    _paymentAnalytics = {
      'totalTransactions': 1250,
      'totalRevenue': 2500000.0, // 2.5M FRW
      'averageTransactionValue': 2000.0,
      'successRate': 0.95,
      'paymentMethods': {
        'mtn_mobile_money': 0.45,
        'airtel_money': 0.30,
        'mpesa': 0.15,
        'card': 0.10,
      },
    };
  }

  Future<void> _loadAdAnalytics() async {
    // Mock ad analytics data
    _adAnalytics = {
      'totalImpressions': 50000,
      'totalClicks': 2500,
      'clickThroughRate': 0.05,
      'totalRevenue': 125000.0, // 125K FRW
      'averageCPM': 2500.0,
      'adTypes': {
        'banner': 0.60,
        'interstitial': 0.30,
        'rewarded': 0.10,
      },
    };
  }

  int _getDaysFromPeriod(String period) {
    switch (period) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '1y':
        return 365;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadData();
            },
            itemBuilder: (context) => _periodOptions.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text('Last $period'),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Last $_selectedPeriod'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subscriptions'),
            Tab(text: 'Commissions'),
            Tab(text: 'Payments'),
            Tab(text: 'Ads'),
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
                    _buildSubscriptionsTab(),
                    _buildCommissionsTab(),
                    _buildPaymentsTab(),
                    _buildAdsTab(),
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
    final totalRevenue = (_subscriptionAnalytics['totalRevenue'] ?? 0.0) +
        (_commissionAnalytics['totalRevenue'] ?? 0.0) +
        (_paymentAnalytics['totalRevenue'] ?? 0.0) +
        (_adAnalytics['totalRevenue'] ?? 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueCard(totalRevenue),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(double totalRevenue) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Revenue',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(totalRevenue)} FRW',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricChip('Subscriptions',
                    _subscriptionAnalytics['totalRevenue'] ?? 0.0),
                const SizedBox(width: 8),
                _buildMetricChip(
                    'Commissions', _commissionAnalytics['totalRevenue'] ?? 0.0),
                const SizedBox(width: 8),
                _buildMetricChip('Ads', _adAnalytics['totalRevenue'] ?? 0.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${NumberFormat('#,###').format(value)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueItem(
              'Subscriptions',
              _subscriptionAnalytics['totalRevenue'] ?? 0.0,
              Colors.blue,
              Icons.subscriptions,
            ),
            _buildRevenueItem(
              'Platform Commissions',
              _commissionAnalytics['totalRevenue'] ?? 0.0,
              Colors.green,
              Icons.percent,
            ),
            _buildRevenueItem(
              'Ad Revenue',
              _adAnalytics['totalRevenue'] ?? 0.0,
              Colors.orange,
              Icons.ad_units,
            ),
            _buildRevenueItem(
              'Transaction Fees',
              _paymentAnalytics['totalRevenue'] ?? 0.0,
              Colors.purple,
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(
      String label, double amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(amount)} FRW',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
                    'Manage Subscriptions',
                    Icons.subscriptions,
                    Colors.blue,
                    () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'View Commissions',
                    Icons.percent,
                    Colors.green,
                    () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Payment Analytics',
                    Icons.payment,
                    Colors.purple,
                    () => _tabController.animateTo(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Ad Performance',
                    Icons.ad_units,
                    Colors.orange,
                    () => _tabController.animateTo(4),
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
      String label, IconData icon, Color color, VoidCallback onPressed) {
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
                    'Active Subscribers',
                    '${_subscriptionAnalytics['totalSubscribers'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Conversion Rate',
                    '${((_subscriptionAnalytics['totalSubscribers'] ?? 0) / 1000 * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
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
                    'Avg. Revenue/User',
                    '${NumberFormat('#,###').format((_subscriptionAnalytics['averageRevenuePerUser'] ?? 0.0))}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Ad CTR',
                    '${((_adAnalytics['clickThroughRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.touch_app,
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
              fontSize: 18,
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

  Widget _buildSubscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionStats(),
          const SizedBox(height: 24),
          _buildSubscriptionPlans(),
          const SizedBox(height: 24),
          _buildInAppPurchases(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Subscribers',
                    '${_subscriptionAnalytics['totalSubscribers'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    '${NumberFormat('#,###').format(_subscriptionAnalytics['totalRevenue'] ?? 0.0)} FRW',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg. Revenue/User',
                    '${NumberFormat('#,###').format(_subscriptionAnalytics['averageRevenuePerUser'] ?? 0.0)} FRW',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Purchases',
                    '${_subscriptionAnalytics['totalPurchases'] ?? 0}',
                    Icons.shopping_cart,
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

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlans() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...SubscriptionService.availablePlans
                .map((plan) => _buildPlanCard(plan)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: plan.isPopular ? Colors.amber.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: plan.isPopular ? Colors.amber.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (plan.isPopular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${NumberFormat('#,###').format(plan.price)} ${plan.currency}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (plan.originalPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${NumberFormat('#,###').format(plan.originalPrice)} ${plan.currency}',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: plan.features
                .take(3)
                .map((feature) => Chip(
                      label: Text(
                        feature,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade100,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppPurchases() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'In-App Purchases',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...SubscriptionService.availablePurchases
                .map((purchase) => _buildPurchaseCard(purchase)),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(InAppPurchase purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: purchase.isConsumable
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    purchase.isConsumable ? 'Consumable' : 'Permanent',
                    style: TextStyle(
                      color: purchase.isConsumable
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${NumberFormat('#,###').format(purchase.price)} ${purchase.currency}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommissionStats(),
          const SizedBox(height: 24),
          _buildCommissionRates(),
          const SizedBox(height: 24),
          _buildRevenueByTier(),
        ],
      ),
    );
  }

  Widget _buildCommissionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    '${NumberFormat('#,###').format(_commissionAnalytics['totalRevenue'] ?? 0.0)} FRW',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Bookings',
                    '${NumberFormat('#,###').format(_commissionAnalytics['totalBookings'] ?? 0.0)} FRW',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg. Commission Rate',
                    '${((_commissionAnalytics['averageCommissionRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Period',
                    _selectedPeriod.toUpperCase(),
                    Icons.calendar_today,
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

  Widget _buildCommissionRates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Rates by Tier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...CommissionService.commissionRates.entries
                .map((entry) => _buildRateCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(String tier, double rate) {
    final tierNames = {
      'free': 'Free Drivers',
      'basic': 'Basic Subscribers',
      'premium': 'Premium Drivers',
      'driverPremium': 'Driver Premium',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tierNames[tier] ?? tier,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(rate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByTier() {
    final revenueByTier =
        _commissionAnalytics['revenueByTier'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue by Driver Tier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...revenueByTier.entries.map((entry) => _buildRevenueByTierCard(
                entry.key, (entry.value as num).toDouble())),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByTierCard(String tier, double revenue) {
    final tierNames = {
      'free': 'Free Drivers',
      'basic': 'Basic Subscribers',
      'premium': 'Premium Drivers',
      'driverPremium': 'Driver Premium',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tierNames[tier] ?? tier,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(revenue)} FRW',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentStats(),
          const SizedBox(height: 24),
          _buildPaymentMethods(),
          const SizedBox(height: 24),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildPaymentStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Transactions',
                    '${NumberFormat('#,###').format(_paymentAnalytics['totalTransactions'] ?? 0)}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    '${NumberFormat('#,###').format(_paymentAnalytics['totalRevenue'] ?? 0.0)} FRW',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg. Transaction',
                    '${NumberFormat('#,###').format(_paymentAnalytics['averageTransactionValue'] ?? 0.0)} FRW',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Success Rate',
                    '${((_paymentAnalytics['successRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
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

  Widget _buildPaymentMethods() {
    final paymentMethods =
        _paymentAnalytics['paymentMethods'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.entries.map(
                (entry) => _buildPaymentMethodCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method, double percentage) {
    final methodNames = {
      'mtn_mobile_money': 'MTN Mobile Money',
      'airtel_money': 'Airtel Money',
      'mpesa': 'M-Pesa',
      'card': 'Credit/Debit Card',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              methodNames[method] ?? method,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Transaction history will be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdStats(),
          const SizedBox(height: 24),
          _buildAdTypes(),
          const SizedBox(height: 24),
          _buildAdPerformance(),
        ],
      ),
    );
  }

  Widget _buildAdStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Performance Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Impressions',
                    '${NumberFormat('#,###').format(_adAnalytics['totalImpressions'] ?? 0)}',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Clicks',
                    '${NumberFormat('#,###').format(_adAnalytics['totalClicks'] ?? 0)}',
                    Icons.touch_app,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Click-Through Rate',
                    '${((_adAnalytics['clickThroughRate'] ?? 0.0) * 100).toStringAsFixed(2)}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    '${NumberFormat('#,###').format(_adAnalytics['totalRevenue'] ?? 0.0)} FRW',
                    Icons.attach_money,
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

  Widget _buildAdTypes() {
    final adTypes = _adAnalytics['adTypes'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Types Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...adTypes.entries
                .map((entry) => _buildAdTypeCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeCard(String type, double percentage) {
    final typeNames = {
      'banner': 'Banner Ads',
      'interstitial': 'Interstitial Ads',
      'rewarded': 'Rewarded Ads',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              typeNames[type] ?? type,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average CPM',
                    '${NumberFormat('#,###').format(_adAnalytics['averageCPM'] ?? 0.0)} FRW',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Revenue per 1K Impressions',
                    '${NumberFormat('#,###').format((_adAnalytics['totalRevenue'] ?? 0.0) / ((_adAnalytics['totalImpressions'] ?? 1) / 1000))} FRW',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
