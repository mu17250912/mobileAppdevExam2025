import 'package:flutter/material.dart';
import '../models/user_subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionStatus extends StatefulWidget {
  final VoidCallback? onSubscriptionChanged;

  const SubscriptionStatus({
    super.key,
    this.onSubscriptionChanged,
  });

  @override
  State<SubscriptionStatus> createState() => _SubscriptionStatusState();
}

class _SubscriptionStatusState extends State<SubscriptionStatus> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  UserSubscription? _currentSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_currentSubscription == null || !_currentSubscription!.isActive) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Limited features available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final subscription = _currentSubscription!;
    final isExpired = subscription.isExpired;
    final isExpiringSoon = subscription.isExpiringSoon;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.shade50
            : isExpiringSoon
                ? Colors.orange.shade50
                : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired
              ? Colors.red.shade200
              : isExpiringSoon
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.warning
                : isExpiringSoon
                    ? Icons.schedule
                    : Icons.check_circle,
            color: isExpired
                ? Colors.red.shade700
                : isExpiringSoon
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.planName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.red.shade700
                        : isExpiringSoon
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                  ),
                ),
                Text(
                  isExpired
                      ? 'Subscription expired'
                      : isExpiringSoon
                          ? 'Expires in ${subscription.daysRemaining} days'
                          : 'Active subscription',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired
                        ? Colors.red.shade600
                        : isExpiringSoon
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/subscription-management');
            },
            child: Text(
              'Manage',
              style: TextStyle(
                color: isExpired
                    ? Colors.red.shade700
                    : isExpiringSoon
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 