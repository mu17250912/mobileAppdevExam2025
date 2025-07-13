import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'user_dashboard_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = SessionManager().userId;
    if (userId == null) return;
    
    setState(() { 
      isLoading = true; 
    });
    
    try {
      final ordersList = await _firebaseService.getUserOrders(userId);
      setState(() {
        orders = ordersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() { 
        isLoading = false; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No orders found', style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final status = order['status'] ?? 'pending';
                    final items = order['items'] as List? ?? [];
                    final total = order['total'] ?? 0;
                    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
                    final paymentStatus = order['payment_status'] ?? 'unpaid';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status, paymentStatus),
                          child: Icon(
                            _getStatusIcon(status, paymentStatus),
                            color: Colors.white,
                          ),
                        ),
                        title: Text('Order #${order['id'].substring(0, 8)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${status[0].toUpperCase()}${status.substring(1)}'),
                            Text('Payment: ${paymentStatus[0].toUpperCase()}${paymentStatus.substring(1)}'),
                            Text('Total: RWF ${total.toStringAsFixed(0)}'),
                            Text('Items: ${items.map((item) => '${item['name']} x${item['quantity']}').join(', ')}'),
                            Text('Placed: ${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                            if (order['payment_amount'] != null)
                              Text('Paid: RWF ${order['payment_amount'].toStringAsFixed(0)}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status, String paymentStatus) {
    if (paymentStatus == 'paid') {
      return Colors.green;
    } else if (status == 'pending') {
      return Colors.orange;
    } else if (status == 'approved') {
      return Colors.blue;
    } else if (status == 'rejected') {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status, String paymentStatus) {
    if (paymentStatus == 'paid') {
      return Icons.payment;
    } else if (status == 'pending') {
      return Icons.hourglass_top;
    } else if (status == 'approved') {
      return Icons.check_circle;
    } else if (status == 'rejected') {
      return Icons.cancel;
    } else {
      return Icons.info;
    }
  }

  Widget _buildDeliveryProgress(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            Text('Pending', style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        );
      case 'approved':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.blue),
            Text('Approved', style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        );
      case 'paid':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, color: Colors.green),
            Text('Paid', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        );
      case 'completed':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, color: Colors.green),
            Text('Delivered', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        );
      case 'rejected':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.red),
            Text('Rejected', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        );
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }
} 