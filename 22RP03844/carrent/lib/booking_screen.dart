import 'package:flutter/material.dart';
import 'receipt_screen.dart';
import 'payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'subscription_screen.dart';
import 'subscription_plans_screen.dart';
import 'booking_store.dart';
import 'user_store.dart';
import 'providers/subscription_provider.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const BookingScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String pickup = '';
  String dropoff = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  int get totalPrice {
    if (startDate == null || endDate == null) return 0;
    final days = endDate!.difference(startDate!).inDays + 1;
    final base = days * (widget.car['price'] as int);
    return base;
  }

  int get rentalDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  int get savings {
    return 0;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _confirmBooking() async {
    if (startDate == null || endDate == null || pickup.isEmpty || dropoff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final rentalDays = this.rentalDays;

    // If user is premium, skip car availability check
    if (subscriptionProvider.isSubscribed) {
      _proceedWithBooking();
      return;
    }

    // Check if car is available for the selected dates
    final isAvailable = await BookingStore.isCarAvailableForDateRange(
      widget.car['id'] ?? '',
      startDate!,
      endDate!,
    );
    
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car is not available for selected dates')),
      );
      return;
    }

    // Check subscription requirement for bookings longer than 2 days
    if (rentalDays > 2 && !subscriptionProvider.isSubscribed) {
      // Show subscription required dialog
      final shouldSubscribe = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Premium Subscription Required'),
          content: Text(
            'You\'re trying to book for $rentalDays days. '
            'Bookings longer than 2 days require a premium subscription. '
            'Would you like to view our subscription plans?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('View Plans'),
            ),
          ],
        ),
      );

      if (shouldSubscribe == true) {
        // Navigate to subscription plans
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionPlansScreen(),
          ),
        );
        
        // If user subscribed, continue with booking
        if (subscriptionProvider.isSubscribed) {
          _proceedWithBooking();
        }
      }
      return;
    }

    _proceedWithBooking();
  }

  void _proceedWithBooking() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = UserStore.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final booking = Booking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        carId: widget.car['id'] ?? '',
        carBrand: widget.car['brand'] ?? '',
        carModel: widget.car['model'] ?? '',
        startDate: startDate!,
        endDate: endDate!,
        pickupLocation: pickup,
        dropoffLocation: dropoff,
        totalPrice: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await BookingStore.createBooking(booking);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed and saved!')),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            booking: booking.toMap(),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Car')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.car['brand']} ${widget.car['model']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Subscription status and rental days info
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final rentalDays = this.rentalDays;
                  final needsSubscription = rentalDays > 2 && !subscriptionProvider.isSubscribed;
                  
                  return Column(
                    children: [
                      if (subscriptionProvider.isSubscribed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Premium Active - Unlimited bookings available',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (rentalDays > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: needsSubscription ? Colors.orange.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: needsSubscription ? Colors.orange.shade200 : Colors.blue.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    needsSubscription ? Icons.warning : Icons.info,
                                    color: needsSubscription ? Colors.orange.shade600 : Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rental Duration: $rentalDays days',
                                    style: TextStyle(
                                      color: needsSubscription ? Colors.orange.shade700 : Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (needsSubscription) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Bookings longer than 2 days require a premium subscription',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SubscriptionPlansScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('View Subscription Plans'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(startDate == null ? 'Start Date' : startDate!.toLocal().toString().split(' ')[0]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: startDate == null ? null : () => _selectDate(context, false),
                      child: Text(endDate == null ? 'End Date' : endDate!.toLocal().toString().split(' ')[0]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Pickup Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => pickup = v),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Drop-off Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => dropoff = v),
              ),
              const SizedBox(height: 16),
              Text('Total Price: ${totalPrice} RWF', style: const TextStyle(fontSize: 18)),
              if (savings > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You saved: $savings RWF!', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Discount applied (10%)', style: const TextStyle(color: Colors.green)),
                  ],
                ),
              const SizedBox(height: 24),
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final rentalDays = this.rentalDays;
                  final needsSubscription = rentalDays > 2 && !subscriptionProvider.isSubscribed;
                  final canBook = rentalDays <= 2 || subscriptionProvider.isSubscribed;
                  
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !canBook) ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBook ? const Color(0xFF667eea) : Colors.grey,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              needsSubscription 
                                  ? 'Premium Required for $rentalDays Days'
                                  : 'Confirm Booking',
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 