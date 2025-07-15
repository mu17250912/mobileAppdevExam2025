import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../models/subscription.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  @override
  _SubscriptionManagementScreenState createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load subscription data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      if (userProvider.userProfile != null) {
        subscriptionProvider.loadUserSubscription(userProvider.userProfile!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
              if (userProvider.userProfile != null) {
                subscriptionProvider.loadUserSubscription(userProvider.userProfile!.uid);
              }
            },
          ),
        ],
      ),
      body: Consumer2<SubscriptionProvider, UserProvider>(
        builder: (context, subscriptionProvider, userProvider, _) {
          if (subscriptionProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Subscription Card
                _buildCurrentSubscriptionCard(subscriptionProvider),
                
                SizedBox(height: 24),
                
                // Billing History
                _buildBillingHistorySection(subscriptionProvider),
                
                SizedBox(height: 24),
                
                // Subscription Actions
                _buildSubscriptionActions(subscriptionProvider, userProvider),
                
                SizedBox(height: 24),
                
                // Subscription Info
                _buildSubscriptionInfoSection(subscriptionProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(SubscriptionProvider subscriptionProvider) {
    final subscription = subscriptionProvider.currentSubscription;
    final statusText = subscriptionProvider.getSubscriptionStatusText();
    final progress = subscriptionProvider.getSubscriptionProgress();

    if (subscription == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50]!,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
                          Icon(
                Icons.subscriptions,
                size: 48,
                color: Colors.grey[400]!,
              ),
            SizedBox(height: 16),
            Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]!,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You are currently on the free plan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500]!,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              child: Text('Upgrade to Premium'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                subscription.isActive ? Icons.star : Icons.star_border,
                color: subscription.isActive ? Colors.amber : Colors.grey,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.plan.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: subscription.isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscription.isActive ? 'ACTIVE' : 'EXPIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: subscription.isActive ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          
          if (subscription.plan.type != SubscriptionType.free) ...[
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300]!,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              '${subscription.daysRemaining} days remaining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          SizedBox(height: 16),
          
          // Subscription details
          _buildSubscriptionDetail('Started', _formatDate(subscription.startDate)),
          _buildSubscriptionDetail('Expires', _formatDate(subscription.endDate)),
          if (subscription.amountPaid != null)
            _buildSubscriptionDetail('Amount Paid', '\$${subscription.amountPaid!.toStringAsFixed(2)}'),
          if (subscription.paymentMethod != null)
            _buildSubscriptionDetail('Payment Method', subscription.paymentMethod!),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingHistorySection(SubscriptionProvider subscriptionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        if (subscriptionProvider.billingHistory.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50]!,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No billing history available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...subscriptionProvider.billingHistory.map((billing) => _buildBillingItem(billing)),
      ],
    );
  }

  Widget _buildBillingItem(BillingInfo billing) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(billing.status),
          child: Icon(
            _getStatusIcon(billing.status),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          '\$${billing.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${_formatDate(billing.billingDate)} • ${billing.status.toUpperCase()}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: billing.invoiceUrl != null
            ? IconButton(
                icon: Icon(Icons.receipt),
                onPressed: () {
                  // Handle invoice download
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invoice download not implemented in demo')),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildSubscriptionActions(SubscriptionProvider subscriptionProvider, UserProvider userProvider) {
    final subscription = subscriptionProvider.currentSubscription;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        
        if (subscription != null && subscription.isActive) ...[
          // Renew subscription
          _buildActionButton(
            icon: Icons.refresh,
            title: 'Renew Subscription',
            subtitle: 'Extend your current plan',
            onTap: () => _showRenewDialog(subscriptionProvider, userProvider),
            color: Colors.blue,
          ),
          
          SizedBox(height: 12),
          
          // Cancel subscription
          _buildActionButton(
            icon: Icons.cancel,
            title: 'Cancel Subscription',
            subtitle: 'Cancel auto-renewal',
            onTap: () => _showCancelDialog(subscriptionProvider, userProvider),
            color: Colors.red,
          ),
        ] else ...[
          // Upgrade subscription
          _buildActionButton(
            icon: Icons.upgrade,
            title: 'Upgrade to Premium',
            subtitle: 'Get access to premium features',
            onTap: () => Navigator.pushNamed(context, '/subscription'),
            color: Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubscriptionInfoSection(SubscriptionProvider subscriptionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Auto-renewal', subscriptionProvider.currentSubscription?.autoRenew == true ? 'Enabled' : 'Disabled'),
              _buildInfoRow('Next billing', subscriptionProvider.currentSubscription?.nextBillingDate != null 
                  ? _formatDate(subscriptionProvider.currentSubscription!.nextBillingDate!)
                  : 'N/A'),
              _buildInfoRow('Transaction ID', subscriptionProvider.currentSubscription?.transactionId ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenewDialog(SubscriptionProvider subscriptionProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renew Subscription'),
        content: Text('Are you sure you want to renew your subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renewSubscription(subscriptionProvider, userProvider);
            },
            child: Text('Renew'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(SubscriptionProvider subscriptionProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription'),
        content: Text('Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription(subscriptionProvider, userProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _renewSubscription(SubscriptionProvider subscriptionProvider, UserProvider userProvider) async {
    try {
      await subscriptionProvider.renewSubscription(
        userId: userProvider.userProfile!.uid,
        transactionId: 'demo_renew_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'demo',
        amountPaid: subscriptionProvider.currentSubscription!.plan.price,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription renewed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to renew subscription: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelSubscription(SubscriptionProvider subscriptionProvider, UserProvider userProvider) async {
    try {
      await subscriptionProvider.cancelSubscription(userProvider.userProfile!.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel subscription: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
} 