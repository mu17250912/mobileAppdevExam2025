import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load Google Play purchases
        final purchasesSnapshot = await FirebaseFirestore.instance
            .collection('purchases')
            .where('userId', isEqualTo: user.uid)
            .orderBy('purchaseDate', descending: true)
            .get();

        // Load mobile money payments
        final mobileMoneySnapshot = await FirebaseFirestore.instance
            .collection('mobile_money_payments')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        final List<Map<String, dynamic>> allPayments = [];

        // Add Google Play purchases
        allPayments.addAll(purchasesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'productId': data['productId'] ?? '',
            'subscriptionType': data['subscriptionType'] ?? '',
            'purchaseDate': data['purchaseDate'] as Timestamp?,
            'amount': data['amount'] ?? 0.0,
            'currency': data['currency'] ?? 'USD',
            'status': data['status'] ?? 'completed',
            'purchaseToken': data['purchaseToken'] ?? '',
            'paymentMethod': 'google_play',
          };
        }));

        // Add mobile money payments
        allPayments.addAll(mobileMoneySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'productId': data['productId'] ?? '',
            'productName': data['productName'] ?? '',
            'purchaseDate': data['createdAt'] as Timestamp?,
            'amount': data['amount'] ?? 0.0,
            'currency': data['currency'] ?? 'USD',
            'status': data['status'] ?? 'pending',
            'provider': data['provider'] ?? '',
            'phoneNumber': data['phoneNumber'] ?? '',
            'paymentMethod': 'mobile_money',
          };
        }));

        // Sort by date (most recent first)
        allPayments.sort((a, b) {
          final dateA = a['purchaseDate'] as Timestamp?;
          final dateB = b['purchaseDate'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        setState(() {
          _payments = allPayments;
        });
      }
    } catch (e) {
      print('Error loading payment history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getProductDisplayName(String productId) {
    switch (productId) {
      case 'smartbudget_premium_monthly':
        return 'Monthly Premium';
      case 'smartbudget_premium_yearly':
        return 'Yearly Premium';
      case 'smartbudget_premium_lifetime':
        return 'Lifetime Premium';
      default:
        return 'Premium Subscription';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount, String currency) {
    return '${currency} ${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmptyState()
              : _buildPaymentList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Payment History',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your payment history will appear here once you make a purchase.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final purchaseDate = payment['purchaseDate'] as Timestamp?;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             payment['paymentMethod'] == 'mobile_money' 
                                 ? (payment['productName'] ?? 'Premium Subscription')
                                 : _getProductDisplayName(payment['productId']),
                             style: GoogleFonts.poppins(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: Theme.of(context).textTheme.titleLarge?.color,
                             ),
                           ),
                           if (payment['paymentMethod'] == 'mobile_money')
                             Text(
                               '${payment['provider']?.toString().toUpperCase() ?? 'MOBILE MONEY'}',
                               style: GoogleFonts.poppins(
                                 fontSize: 12,
                                 color: Theme.of(context).colorScheme.secondary,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                         ],
                       ),
                     ),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: _getStatusColor(payment['status']).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                         payment['status'].toString().toUpperCase(),
                         style: GoogleFonts.poppins(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
                           color: _getStatusColor(payment['status']),
                         ),
                       ),
                     ),
                   ],
                 ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatAmount(payment['amount'], payment['currency']),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                if (purchaseDate != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(purchaseDate.toDate()),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 8),
                
                                 Row(
                   children: [
                     Icon(
                       Icons.payment,
                       size: 16,
                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                     ),
                     const SizedBox(width: 8),
                     Text(
                       payment['paymentMethod'] == 'mobile_money' 
                           ? '${payment['provider']?.toString().toUpperCase() ?? 'MOBILE MONEY'}'
                           : 'Google Play Store',
                       style: GoogleFonts.poppins(
                         fontSize: 14,
                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                       ),
                     ),
                   ],
                 ),
                
                                 if (payment['paymentMethod'] == 'mobile_money' && payment['phoneNumber'] != null) ...[
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Icon(
                         Icons.phone,
                         size: 16,
                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           'Phone: ${payment['phoneNumber']}',
                           style: GoogleFonts.poppins(
                             fontSize: 12,
                             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                           ),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ],
                   ),
                 ] else if (payment['purchaseToken'] != null && payment['purchaseToken'].isNotEmpty) ...[
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Icon(
                         Icons.receipt,
                         size: 16,
                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           'Transaction ID: ${payment['purchaseToken']}',
                           style: GoogleFonts.poppins(
                             fontSize: 12,
                             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                           ),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ],
                   ),
                 ],
              ],
            ),
          ),
        );
      },
    );
  }
} 