import 'package:flutter/material.dart';

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
              onPressed: () {
                // TODO: Implement purchase logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Purchase flow coming soon!')),
                );
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