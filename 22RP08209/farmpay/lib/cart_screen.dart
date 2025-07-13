import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'session_manager.dart';
import 'products_screen.dart';
import 'user_dashboard_screen.dart';
import 'order_selection_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import
import 'package:video_player/video_player.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  late VideoPlayerController _videoController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    final userId = SessionManager().userId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return;
    }
    _loadCartItems();
    _videoController = VideoPlayerController.network(
      'https://samplelib.com/mp4/sample-5s.mp4', // Placeholder video
    )..initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userId = SessionManager().userId;
      if (userId == null) return;
      
      final items = await _firebaseService.getCartItems(userId);
      setState(() {
        cartItems = items;
        _calculateTotal();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart: $e')),
      );
    }
  }

  void _calculateTotal() {
    totalAmount = cartItems.fold(0.0, (sum, item) {
      final price = item['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(index);
    } else {
      try {
        final userId = SessionManager().userId;
        if (userId == null) return;
        
        final updatedItems = List<Map<String, dynamic>>.from(cartItems);
        updatedItems[index]['quantity'] = newQuantity;
        
        await _firebaseService.updateCart(userId, updatedItems);
        await _loadCartItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(int index) async {
    try {
      final userId = SessionManager().userId;
      if (userId == null) return;
      
      final updatedItems = List<Map<String, dynamic>>.from(cartItems);
      updatedItems.removeAt(index);
      
      await _firebaseService.updateCart(userId, updatedItems);
      await _loadCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $e')),
      );
    }
  }

  Future<void> _proceedToCheckout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    try {
      final userId = SessionManager().userId;
      if (userId == null) return;
      
      // Create order using Firebase service
      final orderData = {
        'userId': userId.toString(),
        'items': cartItems,
        'total': totalAmount,
        'currency': 'RWF',
      };
      
      final orderId = await _firebaseService.createOrder(orderData);
      
      // Create notification for admin
      await _firebaseService.createNotification({
        'type': 'order',
        'orderId': orderId,
        'userId': userId.toString(),
        'message': 'New order placed by user $userId',
      });
      
      // Clear cart
      await _firebaseService.clearCart(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order created successfully! Total: RWF ${totalAmount.toStringAsFixed(0)}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to order selection screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(color: Colors.white)),
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
          : cartItems.isEmpty
              ? Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 18)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(item['name'] ?? ''),
                              subtitle: Text('RWF ${(item['price'] ?? 0).toStringAsFixed(0)} x ${item['quantity']} kg'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline),
                                    onPressed: () => _updateQuantity(index, (item['quantity'] ?? 1) - 1),
                                  ),
                                  Text('${item['quantity']}', style: TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline),
                                    onPressed: () => _updateQuantity(index, (item['quantity'] ?? 1) + 1),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Total: RWF ${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _proceedToCheckout,
                            icon: Icon(Icons.shopping_cart_checkout),
                            label: Text('Create Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1976D2),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrderSelectionScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.payment),
                            label: Text('View Pending Orders'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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