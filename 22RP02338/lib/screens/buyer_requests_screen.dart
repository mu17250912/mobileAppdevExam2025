import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';
import '../services/payment_service.dart';

class BuyerRequestsScreen extends StatelessWidget {
  const BuyerRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final buyerName = authProvider.currentUser?.fullName ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Purchase Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('purchase_requests')
            .where('buyerName', isEqualTo: buyerName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No purchase requests found.'));
          }
          final requests = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final data = requests[i].data() as Map<String, dynamic>;
              final requestId = requests[i].id;
              final paymentStatus = data['paymentStatus'] ?? 'pending';
              final requestStatus = data['status'] ?? 'pending';
              
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home, size: 36, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['propertyTitle'] ?? '',
                                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('Offer: \$${data['offer']}', style: AppTextStyles.body2),
                              ],
                            ),
                          ),
                          _buildStatusChip(paymentStatus, requestStatus),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (data['moveInDate'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Move-in: ${_formatDate(data['moveInDate'])}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      
                      if (data['message'] != null && data['message'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Message: ${data['message']}',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      
                      // Contact Owner Button
                      if (paymentStatus != 'paid')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.payment),
                            label: const Text('Contact Owner (Pay \$50)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showPaymentDialog(context, requestId),
                          ),
                        ),
                      
                      if (paymentStatus == 'paid' && requestStatus != 'connected')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Payment completed! Commissioner will connect you soon.',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (requestStatus == 'connected')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.connect_without_contact, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connected with property owner!',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildStatusChip(String paymentStatus, String requestStatus) {
    Color color;
    String label;
    
    if (requestStatus == 'connected') {
      color = AppColors.success;
      label = 'Connected';
    } else if (paymentStatus == 'paid') {
      color = AppColors.warning;
      label = 'Paid';
    } else {
      color = Colors.grey;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString().split('T').first;
  }

  void _showPaymentDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Property Owner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To contact the property owner directly, you need to pay a connection fee of \$50.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'This fee covers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Direct contact with property owner'),
            Text('• Commissioner facilitation'),
            Text('• Property verification'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processPayment(context, requestId);
            },
            child: const Text('Pay \$50'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, String requestId) async {
    // Show payment method selection
    final paymentMethod = await PaymentService.showPaymentMethodDialog(context);
    if (paymentMethod == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing payment...'),
          ],
        ),
      ),
    );

    try {
      // Get user data for payment
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('User not found');
      }

      // Start Flutterwave payment
      final success = await PaymentService.startFlutterwavePayment(
        context: context,
        method: paymentMethod,
        amount: '50', // $50 connection fee
        userName: user.fullName,
        userEmail: user.email,
        userPhone: user.phone,
      );

      if (success) {
        // Update payment status in Firestore
        await FirebaseFirestore.instance
            .collection('purchase_requests')
            .doc(requestId)
            .update({'paymentStatus': 'paid'});
        
        // Get request data for notification
        final requestDoc = await FirebaseFirestore.instance
            .collection('purchase_requests')
            .doc(requestId)
            .get();
        
        if (requestDoc.exists) {
          final requestData = requestDoc.data() as Map<String, dynamic>;
          
          // Create notification for commissioner
          await NotificationService.createPaymentNotification(
            requestId: requestId,
            buyerName: requestData['buyerName'] ?? 'Unknown',
            propertyTitle: requestData['propertyTitle'] ?? 'Unknown Property',
          );
        }

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful!'),
              content: const Text(
                'Your payment has been processed successfully. '
                'The commissioner will now connect you with the property owner within 24 hours.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 