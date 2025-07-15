import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';

class ViewOrdersScreen extends StatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  State<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends State<ViewOrdersScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final List<String> _statuses = ['All', 'Pending', 'Completed', 'Cancelled'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final userRole = authService.userRole;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('View Orders'),
        ),
        body: const Center(
          child: Text('Please log in to view orders'),
        ),
      );
    }

    // Fetch all orders, filter in Dart (no where/orderBy in Firestore query)
    Query ordersQuery = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  debugPrint('Firestore error: $error');
                  if (error.contains('PERMISSION_DENIED')) {
                    return _buildError('Permission denied. Please check your Firestore rules or login again.');
                  } else if (error.contains('network') || error.contains('SocketException')) {
                    return _buildError('No internet connection. Please check your network and try again.');
                  } else {
                    return _buildError('Error loading orders: $error');
                  }
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }
                // Filter by user, status, and search query in Dart
                final orders = snapshot.data!.docs
                    .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                    .where((order) {
                      // Filter by user role
                      if (userRole == 'farmer' && order['buyerId'] != currentUser) return false;
                      if (userRole == 'dealer' && order['dealer'] != currentUser) return false;
                      // Filter by status
                      if (_selectedStatus != 'All' && (order['status'] ?? '').toString().toLowerCase() != _selectedStatus.toLowerCase()) return false;
                      // Filter by search query
                      final productName = (order['productName'] ?? '').toString().toLowerCase();
                      final orderId = (order['id'] ?? '').toString().toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return productName.contains(query) || orderId.contains(query);
                    })
                    // Optionally, sort by orderDate descending in Dart
                    .toList()
                    ..sort((a, b) {
                      final aDate = a['orderDate'] is Timestamp
                          ? (a['orderDate'] as Timestamp).toDate()
                          : DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime.now();
                      final bDate = b['orderDate'] is Timestamp
                          ? (b['orderDate'] as Timestamp).toDate()
                          : DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime.now();
                      return bDate.compareTo(aDate);
                    });
                if (orders.isEmpty) {
                  return _buildEmpty();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order, userRole);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ..._statuses.map((status) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(status),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  selectedColor: Colors.green[200],
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedStatus == status ? Colors.green[900] : Colors.black87,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by product or order ID',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No orders found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Your orders will appear here.', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          // Debug info for development
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Debug info: $message',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, String? userRole) {
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final orderDate = order['orderDate'] is Timestamp
        ? (order['orderDate'] as Timestamp).toDate()
        : DateTime.tryParse(order['orderDate']?.toString() ?? '') ?? DateTime.now();
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['productName'] ?? 'Unknown Product',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: ${order['id']}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      if (userRole == 'dealer')
                        Text('Buyer: ${order['buyerUsername'] ?? order['buyerId'] ?? 'Unknown'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      if (userRole == 'farmer')
                        Text('Dealer: ${order['dealer'] ?? 'Unknown'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(orderDate)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Quantity: ${order['quantity'] ?? 1}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text('Price: RWF ${NumberFormat('#,###').format(order['price'] ?? order['totalAmount'] ?? 0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
            if (userRole == 'dealer' && status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order['id'], 'completed'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Mark Complete'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Fetch order details for notification
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data();
      if (orderData != null) {
        await NotificationService.showOrderNotification(
          orderId: orderId,
          status: newStatus,
          productName: orderData['productName'] ?? 'Product',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
} 