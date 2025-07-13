import 'package:flutter/material.dart';
import '../screens/premium_service.dart';
import '../screens/payment_form_screen.dart';
import '../services/enhanced_notification_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  Future<void> _handleUpgrade() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(
          amount: 4.99,
          plan: 'Monthly Premium',
        ),
      ),
    );

    if (result == true) {
      await PremiumService.setPremium(true);
      if (mounted) {
        // Show push notification
        // EnhancedNotificationService.showLocalNotification(
        //   title: 'Premium Unlocked!',
        //   body: 'Congratulations! You now have access to premium features.',
        // );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium unlocked! Enjoy your new features.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Return true so home screen can refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Go Premium'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 80),
            SizedBox(height: 24),
            Text(
              'Upgrade to Premium', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
              textAlign: TextAlign.center
            ),
            SizedBox(height: 16),
            Text(
              'Unlock these benefits:', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.block, color: Colors.green[800]),
              title: Text('Remove all ads for a distraction-free experience'),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.green[800]),
              title: Text('Access advanced analytics and reports'),
            ),
            ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.green[800]),
              title: Text('Enhanced notifications and reminders'),
            ),
            ListTile(
              leading: Icon(Icons.backup, color: Colors.green[800]),
              title: Text('Cloud backup and sync across devices'),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Monthly Premium Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$4.99/month',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cancel anytime • No commitment',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Upgrade Now'),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
} 