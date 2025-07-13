import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/isoko_app_bar.dart';

class OrderScreen extends StatefulWidget {
  final ProductModel product;

  const OrderScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get buyer data
      final buyerData = await _firestoreService.getUserData(currentUser.uid);
      if (buyerData == null) {
        throw Exception('Buyer data not found');
      }

      final quantity = double.parse(_quantityController.text.trim());
      final totalAmount = quantity * widget.product.pricePerKg;
      final commission = totalAmount * 0.053; // 5.3% commission
      final payout = totalAmount - commission; // Seller payout

      // Create order
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.product.id,
        productName: widget.product.name,
        buyerId: currentUser.uid,
        buyerName: buyerData['fullName'] ?? 'Unknown',
        buyerPhone: buyerData['phone'] ?? 'N/A',
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        quantity: quantity,
        pricePerKg: widget.product.pricePerKg,
        totalAmount: totalAmount,
        commission: commission, // 5.3% commission
        payout: payout, // Seller payout
        status: 'pending',
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createOrder(order);

      // Create notification for seller
      final sellerNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_seller',
        userId: widget.product.sellerId,
        title: 'New Order Received',
        message: '${buyerData['fullName']} has placed an order for ${quantity}kg of ${widget.product.name}',
        type: 'order_placed',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createNotification(sellerNotification);

      // Create notification for buyer
      final buyerNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_buyer',
        userId: currentUser.uid,
        title: 'Order Placed Successfully',
        message: 'Your order for ${quantity}kg of ${widget.product.name} has been placed successfully',
        type: 'order_placed',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createNotification(buyerNotification);

      // Show success dialog with enhanced UI
      await _showOrderSuccessDialog(order);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showOrderSuccessDialog(OrderModel order) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Placed Successfully'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your order has been placed successfully!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Product: ${order.productName}'),
                    Text('Quantity: ${order.quantity} kg'),
                    Text('Total: ${order.totalAmount.toStringAsFixed(0)} RWF'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Next step: Complete payment in "My Orders" to finalize your purchase.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('View Orders'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.green[800] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[800] : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IsokoAppBar(title: 'Place Order'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Product', widget.product.name),
                      _buildDetailRow('Seller', widget.product.sellerName),
                      _buildDetailRow('Price per kg', '${widget.product.pricePerKg.toStringAsFixed(0)} RWF'),
                      _buildDetailRow('Available Quantity', '${widget.product.quantity} kg'),
                      _buildDetailRow('Location', '${widget.product.sellerDistrict}, ${widget.product.sellerSector}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Order form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Quantity (kg)',
                          hintText: 'Enter quantity',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter quantity';
                          }
                          final quantity = double.tryParse(value.trim());
                          if (quantity == null || quantity <= 0) {
                            return 'Please enter a valid quantity';
                          }
                          if (quantity > widget.product.quantity) {
                            return 'Quantity exceeds available stock';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Quantity', '${_quantityController.text.isEmpty ? '0' : _quantityController.text} kg'),
                            _buildSummaryRow('Price per kg', '${widget.product.pricePerKg.toStringAsFixed(0)} RWF'),
                            const Divider(),
                            _buildSummaryRow(
                              'Total Amount', 
                              '${(_quantityController.text.isEmpty ? 0 : double.tryParse(_quantityController.text) ?? 0) * widget.product.pricePerKg} RWF',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Place order button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Place Order'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.green[800] : Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[800] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
} 