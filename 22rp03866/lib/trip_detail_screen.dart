import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// For navigation after booking
// Import RegisterScreen
import 'package:safarigo/payment_screen.dart'; // Import PaymentScreen
import 'package:safarigo/notification_screen.dart'; // Import NotificationScreen

class TripDetailScreen extends StatefulWidget {
  final Map<String, String> park;

  const TripDetailScreen({super.key, required this.park});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  DateTime? _selectedDate;
  int _numberOfPeople = 1;
  bool _isLoading = false;
  bool _isPremiumBooking = false; // New state for premium booking

  double get _basePrice => double.parse(widget.park['price'] ?? '0');
  double get _premiumSurcharge => 50.0; // Example premium surcharge
  double get _totalPrice => (_basePrice * _numberOfPeople) + (_isPremiumBooking ? _premiumSurcharge : 0);

  // Removed _simulatePayment from here, it's now in PaymentScreen

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF234F1E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF234F1E)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookTrip() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date for your trip.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Navigate to payment screen and wait for result
    final bool? paymentSuccess = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(totalPrice: _totalPrice), // Pass the total price
      ),
    );

    if (paymentSuccess == null || !paymentSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled or failed. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to book a trip.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email,
        'tripName': widget.park['name'],
        'tripDescription': widget.park['description'],
        'tripImage': widget.park['image'],
        'bookingDate': _selectedDate!.toIso8601String(),
        'numberOfPeople': _numberOfPeople,
        'status': 'Pending', // Set to Pending for admin approval
        'timestamp': FieldValue.serverTimestamp(),
        'isPremiumBooking': _isPremiumBooking, // Save premium status
        'totalPrice': _totalPrice, // Save total price
      });

      // Prepare booking details to pass to notification screen
      final Map<String, dynamic> bookingData = {
        'tripName': widget.park['name'],
        'bookingDate': _selectedDate!.toIso8601String(),
        'numberOfPeople': _numberOfPeople,
        'isPremiumBooking': _isPremiumBooking,
        'totalPrice': _totalPrice,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip booked successfully!')),
      );

      // Navigate to notifications screen after successful booking and payment
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
            message: 'Your trip has been successfully booked and payment confirmed!',
            bookingDetails: bookingData,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book trip: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.park['image']!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.park['name']!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.park['description']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amenities',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.terrain, color: theme.iconTheme.color, size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Nature Trails', 
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.pets, color: theme.iconTheme.color, size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Wildlife Viewing', 
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.night_shelter, color: theme.iconTheme.color, size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Camping', 
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.landscape, color: theme.iconTheme.color, size: 24),
                            SizedBox(height: 4),
                            Text(
                              'Scenic Views', 
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Booking Details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      trailing: Icon(Icons.calendar_today, color: theme.iconTheme.color),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Number of People:',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<int>(
                            value: _numberOfPeople,
                            items: List.generate(10, (index) => index + 1)
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _numberOfPeople = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Premium Booking (+\$50)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      value: _isPremiumBooking,
                      onChanged: (bool value) {
                        setState(() {
                          _isPremiumBooking = value;
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _bookTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 2,
                              ),
                              child: Text('Book Now (\$${_totalPrice.toStringAsFixed(2)})'),
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
} 