import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_slip_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersScreen extends StatefulWidget {
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('User not authenticated')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getOrdersByBuyer(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.shopping_cart, color: _getStatusColor(order.status)),
                  title: Text(order.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${order.quantity} kg'),
                      Text('Price: ${order.pricePerKg.toStringAsFixed(0)} RWF/kg'),
                      Text('Total: ${order.totalAmount.toStringAsFixed(0)} RWF'),
                      Text('Status: ${order.status}'),
                      Text('Payment: ${order.paymentStatus}'),
                      if (order.rejectionReason != null)
                        Text('Rejection Reason: ${order.rejectionReason!}', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  trailing: order.status == 'pending' && order.paymentStatus == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Cancel Order',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cancel Order'),
                                    content: const Text('Are you sure you want to cancel this order?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Yes, Cancel'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestoreService.deleteOrder(order.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order cancelled.')),
                                  );
                                }
                              },
                            ),
                            ElevatedButton(
                              onPressed: () => _processPayment(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Pay Now'),
                            ),
                          ],
                        )
                      : order.status == 'rejected'
                          ? ElevatedButton(
                              onPressed: () => _reorderProduct(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Re-order'),
                            )
                          : order.status == 'pending' && order.paymentStatus == 'paid'
                              ? const Icon(Icons.pending, color: Colors.orange)
                              : order.paymentStatus == 'paid'
                                  ? ElevatedButton.icon(
                                      onPressed: () => _downloadPaymentSlip(order),
                                      icon: const Icon(Icons.download, size: 16),
                                      label: const Text('Download Slip'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    )
                                  : null,
                ),
              );
            },
          );
        },
      ),
    );
  }



  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.shopping_cart;
    }
  }

  Future<String?> _showMomoAccountDialog() async {
    final TextEditingController momoController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Payment Method'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter your MTN MoMo account number for payment:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: momoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'MTN MoMo Account Number',
                  hintText: 'e.g., 0781234567',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your MoMo account number';
                  }
                  if (!RegExp(r'^07[0-9]{8}$').hasMatch(value.trim())) {
                    return 'Please enter a valid MTN number (07XXXXXXXX)';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (momoController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(momoController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your MoMo account number')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(OrderModel order) async {
    try {
      // Ask for MoMo account number first
      final momoAccountNumber = await _showMomoAccountDialog();
      if (momoAccountNumber == null || momoAccountNumber.trim().isEmpty) {
        return; // User cancelled
      }

      // Show payment confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay ${order.totalAmount.toStringAsFixed(0)} RWF for ${order.quantity}kg of ${order.productName}?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method: MTN MoMo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            momoAccountNumber,
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Update order with MoMo account number
        await _firestoreService.updateOrderWithMomoAccount(order.id, momoAccountNumber);
        
        // Process payment and update order
        await _firestoreService.processPayment(order.id, order.productId, order.quantity);
        
        // Show success dialog with download option
        await _showPaymentSuccessDialog(order);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reorderProduct(OrderModel rejectedOrder) async {
    try {
      // Get the product details
      final product = await _firestoreService.getProductById(rejectedOrder.productId);
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product no longer available.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if product is still available
      if (product.quantity < rejectedOrder.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only ${product.quantity}kg available. Original order was for ${rejectedOrder.quantity}kg.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show re-order confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Re-order Product'),
          content: Text('Place the same order for ${rejectedOrder.quantity}kg of ${rejectedOrder.productName} at ${rejectedOrder.pricePerKg.toStringAsFixed(0)} RWF/kg?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Re-order'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Create new order with same details
        final currentUser = _authService.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get buyer data
        final buyerData = await _firestoreService.getUserData(currentUser.uid);
        if (buyerData == null) {
          throw Exception('Buyer data not found');
        }

        final totalAmount = rejectedOrder.quantity * rejectedOrder.pricePerKg;
        final commission = totalAmount * 0.053; // 5.3% commission
        final payout = totalAmount - commission; // Seller payout

        // Create new order
        final newOrder = OrderModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: rejectedOrder.productId,
          productName: rejectedOrder.productName,
          buyerId: currentUser.uid,
          buyerName: buyerData['fullName'] ?? 'Unknown',
          buyerPhone: buyerData['phone'] ?? 'N/A',
          sellerId: rejectedOrder.sellerId,
          sellerName: rejectedOrder.sellerName,
          quantity: rejectedOrder.quantity,
          pricePerKg: rejectedOrder.pricePerKg,
          totalAmount: totalAmount,
          commission: commission,
          payout: payout,
          status: 'pending',
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
        );

        await _firestoreService.createOrder(newOrder);

        // Create notification for seller
        final sellerNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_seller_reorder',
          userId: rejectedOrder.sellerId,
          title: 'Re-order Received',
          message: '${buyerData['fullName']} has re-ordered ${rejectedOrder.quantity}kg of ${rejectedOrder.productName}',
          type: 'order_placed',
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createNotification(sellerNotification);

        // Create notification for buyer
        final buyerNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_buyer_reorder',
          userId: currentUser.uid,
          title: 'Re-order Placed Successfully',
          message: 'Your re-order for ${rejectedOrder.quantity}kg of ${rejectedOrder.productName} has been placed successfully',
          type: 'order_placed',
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createNotification(buyerNotification);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Re-order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to re-order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPaymentSuccessDialog(OrderModel order) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 28),
              const SizedBox(width: 12),
              const Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your payment of ${order.totalAmount.toStringAsFixed(0)} RWF has been processed successfully.',
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
                      'Order Details:',
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
              const SizedBox(height: 16),
              Text(
                'Would you like to download your payment slip as proof of payment?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadPaymentSlip(order);
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Slip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }



  Future<void> _downloadPaymentSlip(OrderModel order) async {
    try {
      // Show loading indicator with better UI
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Generating payment slip...'),
                const SizedBox(height: 8),
                Text(
                  'This should take less than 5 seconds',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Shorter timeout to prevent long waits - reduced to 5 seconds
      final timeoutDuration = const Duration(seconds: 5);
      
      // Generate PDF with timeout
      final filePath = await PaymentSlipService.generatePaymentSlip(order)
          .timeout(timeoutDuration, onTimeout: () {
        throw Exception('PDF generation timed out. Please try again.');
      });
      
      // Verify file was actually created
      final fileInfo = await PaymentSlipService.verifyFileExists(filePath);
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                const SizedBox(width: 8),
                const Text('Payment Slip Downloaded'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your payment slip has been saved successfully!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
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
                      Row(
                        children: [
                          Icon(Icons.folder, color: Colors.green[700], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'File Saved To:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fileInfo['exists'] ? 'File saved successfully!' : 'File location unknown',
                        style: TextStyle(
                          color: fileInfo['exists'] ? Colors.green[700] : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filePath.contains('/Download') ? 'Saved to: Downloads Folder' : 'Saved to: App Documents',
                        style: TextStyle(
                          color: filePath.contains('/Download') ? Colors.green[600] : Colors.blue[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Filename: ${filePath.split('/').last}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (fileInfo['exists'] && fileInfo['sizeInKB'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Size: ${fileInfo['sizeInKB']} KB',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This PDF serves as proof of payment. Keep it for your records.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try to open the file
                  try {
                    final uri = Uri.file(filePath);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      // Show a snackbar if we can't open the file
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File saved to: $filePath'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    // Show a snackbar with the file path
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('File saved to: $filePath'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open File'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Print error for debugging
      print('Payment slip error: $e');
      
      // Show user-friendly error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                const Text('Download Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to download payment slip. Please try again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Check storage permissions\n• Ensure sufficient storage space\n• Try again in a moment',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _downloadPaymentSlip(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          );
        },
      );
    }
  }



  Future<void> _testPDFGeneration() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Testing PDF generation...'),
              ],
            ),
          );
        },
      );

      // Test simple PDF generation
      final filePath = await PaymentSlipService.generateSimpleTestPDF();
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                const SizedBox(width: 8),
                const Text('Test PDF Generated'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test PDF generated successfully!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filePath,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                const Text('Test Failed'),
              ],
            ),
            content: Text(
              'Test PDF generation failed: $e',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
} 