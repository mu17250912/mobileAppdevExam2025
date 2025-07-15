import 'package:flutter/material.dart';
import 'session_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  bool isLoading = false;

  IconData getProductIcon(String category) {
    switch (category) {
      case 'Nitrogen':
        return Icons.grass;
      case 'Phosphate':
        return Icons.eco;
      case 'Potassium':
        return Icons.local_florist;
      case 'Balanced':
        return Icons.balance;
      case 'Organic':
        return Icons.eco;
      case 'Micronutrients':
        return Icons.science;
      default:
        return Icons.agriculture;
    }
  }

  Color getProductColor(String category) {
    switch (category) {
      case 'Nitrogen':
        return Colors.green;
      case 'Phosphate':
        return Colors.blue;
      case 'Potassium':
        return Colors.orange;
      case 'Balanced':
        return Colors.purple;
      case 'Organic':
        return Colors.brown;
      case 'Micronutrients':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> addToCart() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userId = SessionManager().userId;
      if (userId == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      }
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(userId.toString());
      final cartDoc = await cartRef.get();
      List<dynamic> items = [];
      if (cartDoc.exists) {
        items = cartDoc.data()!["items"] ?? [];
      }
      // Check if product already in cart
      final existingIndex = items.indexWhere((item) => item['productId'] == widget.product['id']);
      if (existingIndex != -1) {
        items[existingIndex]['quantity'] += quantity;
      } else {
        items.add({
          'productId': widget.product['id'],
          'name': widget.product['name'],
          'price': widget.product['price'],
          'category': widget.product['category'],
          'quantity': quantity,
        });
      }
      await cartRef.set({'items': items}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.product['name']} x$quantity to cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.product['category'] ?? 'Other';
    final icon = getProductIcon(category);
    final color = getProductColor(category);
    final price = widget.product['price'] ?? 0.0;
    final totalPrice = price * quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Product Details'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image/icon
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 60,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    widget.product['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    'RWF ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'] ?? 'No description available.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quantity selector
                  Row(
                    children: [
                      const Text('Quantity (kg):', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total price
                  Text(
                    'Total: RWF ${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  // Add to Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isLoading ? null : addToCart,
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
} 