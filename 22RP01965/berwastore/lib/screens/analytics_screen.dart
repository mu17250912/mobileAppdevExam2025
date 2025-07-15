import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _SalesSummaryWidget(),
            const SizedBox(height: 24),
            const Text('Stock In/Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _StockInOutWidget(),
          ],
        ),
      ),
    );
  }
}

class _SalesSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading sales summary.'));
        }
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final orders = snapshot.data!.docs;
        double today = 0, week = 0, month = 0;
        final now = DateTime.now();
        for (final o in orders) {
          final data = o.data() as Map<String, dynamic>;
          final date = (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : null;
          if (date == null) continue;
          final total = double.tryParse(data['total']?.toString() ?? data['price']?.toString() ?? '0') ?? 0;
          if (date.year == now.year && date.month == now.month && date.day == now.day) today += total;
          if (date.isAfter(now.subtract(const Duration(days: 7)))) week += total;
          if (date.year == now.year && date.month == now.month) month += total;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today: RWF ${today.toStringAsFixed(2)}'),
            Text('This Week: RWF ${week.toStringAsFixed(2)}'),
            Text('This Month: RWF ${month.toStringAsFixed(2)}'),
          ],
        );
      },
    );
  }
}

class _StockInOutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stock info.'));
        }
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final products = snapshot.data!.docs;
        int totalStock = 0;
        for (final p in products) {
          final data = p.data() as Map<String, dynamic>;
          totalStock += int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
        }
        return Text('Current Stock: $totalStock items');
      },
    );
  }
} 