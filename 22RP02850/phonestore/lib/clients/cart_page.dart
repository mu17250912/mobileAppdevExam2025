import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';

const Color kPrimaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF5F6FA);

// PAYPAL SANDBOX CONFIGURATION
const String clientId =
    'ATJ8qOpROw-bpvAzSPyUNH4SmIxj3nkVMmwSpiw2xLs_cCtfIRt-M9LcbIIkviwTjzalyM-Q_MyPkZjg';
const String secretKey =
    'EDi-lHgYQmZr80vYsJKsSrPQst5PR7bXLAn9AG-UemRsjfjzTGQ78sCM4BAlUj8IgwGzd4dIpQs9VnJa';

const String kStoreName = 'ElectroMat';
const String kLogoUrl = 'assets/phonestorelogo.jpg';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  bool _loading = true;
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    _cartService.getCartItems().listen((items) {
      if (mounted) {
        setState(() {
          _cartItems = items;
          _loading = false;
        });
      }
    });
  }

  void _updateQuantity(int index, int delta) async {
    final item = _cartItems[index];
    final newQty = item.quantity + delta;
    
    if (newQty <= 0) {
      await _cartService.removeFromCart(item.productId);
      // Log remove_from_cart event
      await FirebaseAnalytics.instance.logEvent(
        name: 'remove_from_cart',
        parameters: {
          'product_id': item.productId,
          'product_name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        },
      );
    } else {
      await _cartService.updateQuantity(item.productId, newQty);
    }
  }

  void _addToCart(Product product, String userId) async {
    await _cartService.addToCart(CartItem(
      id: '',
      productId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: 1,
      sellerId: product.sellerId,
      addedAt: DateTime.now(),
    ));
    // Log add_to_cart event
    await FirebaseAnalytics.instance.logEvent(
      name: 'add_to_cart',
      parameters: {
        'product_id': product.id,
        'product_name': product.name,
        'price': product.price,
        'quantity': 1,
        'seller_id': product.sellerId,
      },
    );
  }

  void _beginCheckout() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'begin_checkout',
      parameters: {
        'cart_total': _getTotal(),
        'cart_items': _cartItems.length,
      },
    );
  }

  double _getTotal() {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please login first'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cartItems.isEmpty) {
      return const Center(child: Text('Your cart is empty'));
    }
    
    final totalCartPrice = _getTotal();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cartItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              final quantity = item.quantity;
                              final totalPrice = item.totalPrice;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.imageUrl.isNotEmpty
                                        ? Image.network(item.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle, color: kPrimaryColor, size: 28),
                                              onPressed: () => _updateQuantity(index, 1),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle, color: Colors.black54, size: 28),
                                              onPressed: () => _updateQuantity(index, -1),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Total: £${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 8),
                                        Text('Price: £${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.delete, color: Colors.white),
                                                label: const Text('Remove', style: TextStyle(color: Colors.white)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                                onPressed: () async {
                                                  await _cartService.removeFromCart(item.productId);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Divider(thickness: 2, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('£${totalCartPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kPrimaryColor)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                                  label: const Text('Pay with paypal', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onPressed: () async {
                                    if (totalCartPrice <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cart is empty or total is zero.')),
                                      );
                                      return;
                                    }
                                    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('PayPal payment is only available on Android and iOS.')),
                                      );
                                      return;
                                    }
                                    // Log begin_checkout event
                                    _beginCheckout();
                                    try {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => UsePaypal(
                                            sandboxMode: true,
                                            clientId: clientId,
                                            secretKey: secretKey,
                                            returnURL: "https://samplesite.com/return",
                                            cancelURL: "https://samplesite.com/cancel",
                                            transactions: [
                                              {
                                                "amount": {
                                                  "total": totalCartPrice.toStringAsFixed(2),
                                                  "currency": "GBP",
                                                  "details": {
                                                    "subtotal": totalCartPrice.toStringAsFixed(2),
                                                    "shipping": '0',
                                                    "shipping_discount": 0
                                                  }
                                                },
                                                "description": "Payment for items in cart at ElectroMat",
                                                "item_list": {
                                                  "items": [
                                                    for (final item in _cartItems)
                                                      {
                                                        "name": item.name,
                                                        "quantity": item.quantity.toString(),
                                                        "price": item.price.toStringAsFixed(2),
                                                        "currency": "GBP"
                                                      }
                                                  ]
                                                }
                                              }
                                            ],
                                            note: "Thank you for your purchase!",
                                            onSuccess: (Map params) async {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Payment successful!')),
                                              );
                                              // Create order using CartService
                                              try {
                                                final order = await _cartService.createOrder(
                                                  paymentMethod: 'PayPal',
                                                  paymentId: params['paymentId']?.toString(),
                                                  tax: 0.0,
                                                  shipping: 0.0,
                                                  status: 'paid', // Mark as paid after successful payment
                                                );
                                                // Log payment analytics event
                                                await FirebaseAnalytics.instance.logEvent(
                                                  name: 'payment_completed',
                                                  parameters: {
                                                    'order_id': order.id,
                                                    'amount': order.total,
                                                    'seller_ids': order.sellerIds.join(','),
                                                    'buyer_id': order.userId,
                                                    'payment_method': 'PayPal',
                                                    'status': order.status,
                                                  },
                                                );
                                                
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Order created successfully! Order ID:  [${order.id}')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to create order: $e')),
                                                );
                                              }
                                            },
                                            onError: (error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Payment error: $error')),
                                              );
                                            },
                                            onCancel: (params) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Payment cancelled.')),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to start PayPal payment: $e')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
