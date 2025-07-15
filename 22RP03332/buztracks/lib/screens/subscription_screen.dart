import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  Map<String, dynamic>? _currentSubscription;
  Map<String, dynamic>? _usageStats;
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      final usageStats = await _subscriptionService.getUsageStatistics();
      final paymentHistory = await _subscriptionService.getPaymentHistory();

      setState(() {
        _currentSubscription = subscription;
        _usageStats = usageStats;
        _paymentHistory = paymentHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeSubscription(SubscriptionPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _subscriptionService.upgradeSubscription(plan);
      
      if (success) {
        await _loadSubscriptionData();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription upgraded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade subscription. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600);
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premium),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Section
                  _buildCurrentPlanSection(context, isFrench),
                  const SizedBox(height: 24),

                  // Usage Statistics
                  _buildUsageSection(context, isFrench),
                  const SizedBox(height: 24),

                  // Available Plans
                  _buildPlansSection(context, isFrench),
                  const SizedBox(height: 24),

                  // Payment History
                  _buildPaymentHistorySection(context, isFrench),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanSection(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);
    final plan = _currentSubscription?['plan'] ?? 'free';
    final isActive = _currentSubscription?['isActive'] ?? false;
    final expiresAt = _currentSubscription?['expiresAt'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: mainColor, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.currentPlan,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isActive 
                ? AppLocalizations.of(context)!.active
                : AppLocalizations.of(context)!.inactive,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.expiresOn}: ${DateFormat('dd/MM/yyyy').format((expiresAt as Timestamp).toDate())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, bool isFrench) {
    if (_usageStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.usage,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            context,
            AppLocalizations.of(context)!.products,
            _usageStats!['products']['used'],
            _usageStats!['products']['limit'],
            _usageStats!['products']['percentage'],
            Icons.inventory,
          ),
          const SizedBox(height: 8),
          _buildUsageItem(
            context,
            AppLocalizations.of(context)!.customers,
            _usageStats!['customers']['used'],
            _usageStats!['customers']['limit'],
            _usageStats!['customers']['percentage'],
            Icons.people,
          ),
          const SizedBox(height: 8),
          _buildUsageItem(
            context,
            AppLocalizations.of(context)!.sales30Days,
            _usageStats!['sales']['used'],
            _usageStats!['sales']['limit'],
            _usageStats!['sales']['percentage'],
            Icons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String title,
    int used,
    int limit,
    double percentage,
    IconData icon,
  ) {
    final isUnlimited = limit == -1;
    final progressColor = percentage > 80 ? Colors.red : Colors.green;

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: isUnlimited ? 0 : (percentage / 100),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlimited 
                        ? '$used'
                        : '$used / $limit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlansSection(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.availablePlans,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...SubscriptionPlan.values.where((plan) => plan != SubscriptionPlan.free).map((plan) {
          final planData = SubscriptionService.plans[plan]!;
          final isCurrentPlan = _currentSubscription?['plan'] == plan.name;
          final isSelected = _selectedPlan == plan;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isSelected ? mainColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? mainColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          planData['name'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? mainColor : null,
                          ),
                        ),
                        if (isCurrentPlan)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.current,
                              style: const TextStyle(
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
                      _subscriptionService.formatCurrency(
                        planData['price'].toDouble(),
                        planData['currency'],
                      ),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (planData['billing_cycle'] != null)
                      Text(
                        '/${planData['billing_cycle']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),
                    ...(planData['features'] as List<String>).map((feature) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isCurrentPlan) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _upgradeSubscription(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.chooseThisPlan,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentHistorySection(BuildContext context, bool isFrench) {
    if (_paymentHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.paymentHistory,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._paymentHistory.take(5).map((payment) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['plan'].toString().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(
                          (payment['paymentDate'] as Timestamp).toDate(),
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    _subscriptionService.formatCurrency(
                      payment['amount'].toDouble(),
                      payment['currency'],
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 