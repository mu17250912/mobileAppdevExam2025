import 'package:flutter/material.dart';
import '../screens/premium_service.dart'; // Correct import for PremiumService

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Go Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 80),
            SizedBox(height: 24),
            Text('Upgrade to Premium', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Text('Unlock these benefits:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.block, color: Colors.green[800]),
              title: Text('Remove all ads for a distraction-free experience'),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.green[800]),
              title: Text('Access advanced analytics and reports'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Simulated Payment'),
                    content: Text('This is a simulated payment for assessment purposes. Proceed to unlock premium features?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Pay & Upgrade'),
                      ),
                    ],
                  ),
                );
                if (result == true) {
                  // Simulate payment success
                  await PremiumService.setPremium(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Premium unlocked! Enjoy your new features.')),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Upgrade Now'),
            ),
          ],
        ),
      ),
    );
  }
} 