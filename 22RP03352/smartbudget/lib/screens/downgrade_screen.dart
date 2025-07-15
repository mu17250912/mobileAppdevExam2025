import 'package:flutter/material.dart';
import '../screens/premium_service.dart';
import '../services/analytics_service.dart';

class DowngradeScreen extends StatefulWidget {
  const DowngradeScreen({super.key});

  @override
  State<DowngradeScreen> createState() => _DowngradeScreenState();
}

class _DowngradeScreenState extends State<DowngradeScreen> {
  bool _isProcessing = false;

  Future<void> _handleDowngrade() async {
    setState(() => _isProcessing = true);

    try {
      await PremiumService.setPremium(false);
      await AnalyticsService.logFeatureUsage(featureName: 'downgrade_to_freemium');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully downgraded to Freemium.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to downgrade. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Downgrade'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to downgrade to Freemium?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'You will lose access to:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Advanced Analytics & Reports'),
            Text('• Enhanced Analytics'),
            Text('• Data Export functionality'),
            Text('• Ad-free experience'),
            SizedBox(height: 16),
            Text(
              'You can upgrade again anytime!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDowngrade();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Downgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downgrade to Freemium'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 80),
            SizedBox(height: 24),
            Text(
              'Downgrade to Freemium', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
              textAlign: TextAlign.center
            ),
            SizedBox(height: 16),
            Text(
              'What you\'ll lose:', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.red),
              title: Text('Advanced Analytics & Reports'),
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.red),
              title: Text('Enhanced Analytics'),
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.red),
              title: Text('Data Export functionality'),
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text('Ad-free experience'),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Freemium Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Free',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Core budgeting features • Banner ads',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            _isProcessing
              ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing downgrade...'),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Downgrade Now'),
                ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Keep Premium'),
            ),
          ],
        ),
      ),
    );
  }
} 