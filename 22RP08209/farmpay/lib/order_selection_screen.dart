import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'payment_screen.dart';
import 'user_dashboard_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import

class OrderSelectionScreen extends StatefulWidget {
  const OrderSelectionScreen({Key? key}) : super(key: key);

  @override
  State<OrderSelectionScreen> createState() => _OrderSelectionScreenState();
}

class _OrderSelectionScreenState extends State<OrderSelectionScreen> {
  List<Map<String, dynamic>> pendingOrders = [];
  Set<String> selectedOrderIds = {};
  bool isLoading = true;
  double totalSelectedAmount = 0.0;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = SessionManager().userId;
      if (userId == null) return;

      final orders = await _firebaseService.getPendingOrders(userId);
      setState(() {
        pendingOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  void _toggleOrderSelection(String orderId, double amount) {
    setState(() {
      if (selectedOrderIds.contains(orderId)) {
        selectedOrderIds.remove(orderId);
        totalSelectedAmount -= amount;
      } else {
        selectedOrderIds.add(orderId);
        totalSelectedAmount += amount;
      }
    });
  }

  void _selectAllOrders() {
    setState(() {
      selectedOrderIds.clear();
      totalSelectedAmount = 0.0;
      
      for (final order in pendingOrders) {
        selectedOrderIds.add(order['id']);
        totalSelectedAmount += (order['total'] ?? 0.0).toDouble();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedOrderIds.clear();
      totalSelectedAmount = 0.0;
    });
  }

  void _proceedToPayment() {
    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one order to pay for')),
      );
      return;
    }

    // For now, we'll handle one order at a time
    // In the future, you can modify this to handle multiple orders
    final selectedOrderId = selectedOrderIds.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(orderId: selectedOrderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Orders to Pay', style: TextStyle(color: Colors.white)),
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
          : pendingOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending orders',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add items to cart and create orders first',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Selection controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedOrderIds.length} of ${pendingOrders.length} orders selected',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: _selectAllOrders,
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: _clearSelection,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),

                    // Orders list
                    Expanded(
                      child: ListView.builder(
                        itemCount: pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = pendingOrders[index];
                          final orderId = order['id'];
                          final isSelected = selectedOrderIds.contains(orderId);
                          final orderAmount = (order['total'] ?? 0.0).toDouble();
                          final orderItems = List<Map<String, dynamic>>.from(order['items'] ?? []);
                          final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) => _toggleOrderSelection(orderId, orderAmount),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${orderId.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'RWF ${orderAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${orderItems.length} items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: orderItems.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        ...orderItems.take(3).map((item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            '• ${item['name']} x${item['quantity']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        )),
                                        if (orderItems.length > 3)
                                          Text(
                                            '... and ${orderItems.length - 3} more items',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),

                    // Payment button
                    if (selectedOrderIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Selected:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'RWF ${totalSelectedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _proceedToPayment,
                              icon: const Icon(Icons.payment),
                              label: const Text('Pay Selected Orders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
} 