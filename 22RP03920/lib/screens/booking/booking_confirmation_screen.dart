import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert'; // Added for jsonEncode and jsonDecode
import 'package:http/http.dart' as http; // Added for http requests

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    FirebaseAnalytics.instance.logScreenView(screenName: 'BookingConfirmationScreen');
    
    final doctorName = args?['doctorName'] ?? 'Doctor';
    final date = args?['date'] ?? 'Date';
    final time = args?['time'] ?? 'Time';
    final specialty = args?['specialty'] ?? 'Specialty';
    final status = args?['status'] ?? 'pending';
    final double doctorFee = args?['doctorFee'] ?? 10000; // Example fee
    final double commission = doctorFee * 0.1; // 10% commission
    final double total = doctorFee + commission;

    Future<void> _payWithStripe(BuildContext context, double total) async {
      try {
        // 1. Call your backend to create a PaymentIntent and get the clientSecret
        final response = await http.post(
          Uri.parse('https://your-backend.com/create-payment-intent'), // TODO: Replace with your backend URL
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'amount': (total * 100).toInt(), 'currency': 'rwf'}), // Amount in smallest currency unit
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to create PaymentIntent');
        }
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'];

        // 2. Present payment sheet
        await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SmartCare',
        ));
        await Stripe.instance.presentPaymentSheet();

        // 3. On success, show confirmation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Payment Success'),
            content: Text('Your payment was successful!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stripe payment failed: $e')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Request'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback),
            tooltip: 'Send Feedback',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Feedback'),
                  content: const Text('To report a confirmation issue, email support@smartcare.com or use the Contact Us option in the app drawer.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Semantics(
              label: 'Booking confirmation. Doctor: $doctorName, Specialty: $specialty, Date: $date, Time: $time, Status: $status.',
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: status == 'pending' 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'pending' ? Icons.pending_actions : Icons.check_circle,
                        size: 64,
                        color: status == 'pending' ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      status == 'pending' ? 'Request Submitted!' : 'Appointment Confirmed!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      status == 'pending' 
                          ? 'Your appointment request has been submitted successfully. Our admin team will review it and notify you of the decision.'
                          : 'Your appointment has been confirmed successfully.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Appointment Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(theme, 'Doctor', doctorName),
                          const SizedBox(height: 12),
                          _buildDetailRow(theme, 'Specialty', specialty),
                          const SizedBox(height: 12),
                          _buildDetailRow(theme, 'Date', date),
                          const SizedBox(height: 12),
                          _buildDetailRow(theme, 'Time', time),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Status Info
                    if (status == 'pending')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You will receive a notification once your request is reviewed.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Commission Breakdown
                    const SizedBox(height: 16),
                    Text('Payment Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetailRow(theme, 'Doctor Fee', 'RWF ${doctorFee.toStringAsFixed(0)}'),
                    _buildDetailRow(theme, 'App Commission (10%)', 'RWF ${commission.toStringAsFixed(0)}'),
                    _buildDetailRow(theme, 'Total', 'RWF ${total.toStringAsFixed(0)}'),
                    const SizedBox(height: 24),
                    // Stripe Payment Button
                    ElevatedButton.icon(
                      icon: Icon(Icons.payment),
                      label: Text('Proceed to Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/payment',
                          arguments: {
                            'amount': total,
                            'bookingDetails': {
                              'doctorName': doctorName,
                              'date': date,
                              'time': time,
                              'specialty': specialty,
                              'status': status,
                            },
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/home', 
                          (route) => false
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/my_bookings'),
                      child: Text(
                        'View My Bookings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
} 