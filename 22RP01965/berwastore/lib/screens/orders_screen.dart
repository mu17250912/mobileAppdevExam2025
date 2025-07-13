import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading orders.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }
          final orders = snapshot.data!.docs;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final doc = orders[i];
              final data = doc.data() as Map<String, dynamic>;
              final items = (data['items'] as List?) ?? [];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('Order #${doc.id.substring(0, 6)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buyer: ${data['buyerName'] ?? data['buyerId'] ?? 'Unknown Buyer'}'),
                      Text('Total: RWF ${data['total'] ?? ''}'),
                      Text('Payment: ${data['method'] ?? ''}'),
                      Text('Date: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal().toString().split(".")[0] : ''}'),
                      const SizedBox(height: 4),
                      Text('Items:'),
                      ...items.map((item) => Text('- ${item['name']} (RWF ${item['price']})')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 