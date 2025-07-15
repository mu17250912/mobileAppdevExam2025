import 'package:flutter/material.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder for alert info
            Row(
              children: [
                Icon(Icons.warning, color: Colors.redAccent, size: 32),
                const SizedBox(width: 12),
                Text('Crime', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Active', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Description of the alert goes here. This is a placeholder for the full alert details.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text('123 Main St, City'),
                const Spacer(),
                Text('2 min ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            // Placeholder for image
            Container(
              height: 180,
              color: Colors.grey[300],
              child: const Center(child: Text('Alert Image Placeholder')),
            ),
            const SizedBox(height: 24),
            // Placeholder for map
            Container(
              height: 120,
              color: Colors.grey[200],
              child: const Center(child: Text('Map Placeholder')),
            ),
            const SizedBox(height: 24),
            // Placeholder for comments
            Text('Comments', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Container(
              height: 80,
              color: Colors.grey[100],
              child: const Center(child: Text('Comments Placeholder')),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Mark as safe
                    },
                    child: const Text("I'm Safe"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Mark as helping
                    },
                    child: const Text('I Can Help'),
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