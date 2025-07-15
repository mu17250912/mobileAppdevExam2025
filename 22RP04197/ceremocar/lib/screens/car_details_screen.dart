import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarDetailsScreen extends StatefulWidget {
  const CarDetailsScreen({super.key});
  
  @override
  _CarDetailsScreenState createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  int _selectedTab = 0;
  int _selectedBottomNav = 2; // Book tab selected
  bool isBooking = false;

  // Add controllers and state for booking form
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _withDriver = false;
  bool _withDecoration = false;
  final TextEditingController _specialRequestController = TextEditingController();
  String? _bookingError;

  // Remove old _bookTab and related booking state
  // Add new method to launch booking stepper modal
  void _startBookingFlow(Map<String, dynamic> carData) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: _BookingStepper(carData: carData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments;
    String? carId;
    if (args is String) {
      carId = args;
    } else if (args is Map && args['carId'] != null) {
      carId = args['carId'] as String;
    }
    if (carId == null) {
      return Scaffold(
        body: Center(child: Text('No car ID provided!')),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('cars').doc(carId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text('Car not found!')),
          );
        }
        final carData = snapshot.data!.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/available_cars_screen',
              (route) => false,
            );
          },
        ),
        title: Text(carData['name'] ?? 'Car Details'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: carData['image'].toString().startsWith('http')
                  ? Image.network(carData['image'], height: 160, width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(carData['image'], height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 18),
            Text(carData['name'], style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(carData['price'], style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Details')),
                ButtonSegment(value: 1, label: Text('Customize')),
                ButtonSegment(value: 2, label: Text('Book')),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedTab = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(theme.colorScheme.surface),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedTab == 0
                  ? _detailsTab(theme)
                  : _selectedTab == 1
                      ? _customizeTab(carData, theme)
                      : Center(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Start Booking'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 2,
                            ),
                            onPressed: () => _startBookingFlow(carData),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedBottomNav,
        onDestinationSelected: (index) {
          setState(() {
            _selectedBottomNav = index;
          });
          if (index == 0) {
            Navigator.pushNamed(context, '/available_cars_screen');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/my_bookings_screen');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Bookings'),
        ],
        height: 70,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.secondary.withOpacity(0.1),
      ),
    );
      },
    );
  }

  Widget _detailsTab(ThemeData theme) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _featureRow('5 seats • Automatic', theme),
        _featureRow('GPS Navigation', theme),
        _featureRow('Premium sound system', theme),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: const Text('Book Now'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
          ),
          onPressed: () {
            setState(() {
              _selectedTab = 2;
            });
          },
        ),
      ],
    );
  }

  Widget _featureRow(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _customizeTab(Map<String, dynamic> carData, ThemeData theme) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('With Driver'),
          value: _withDriver,
          onChanged: (val) => setState(() => _withDriver = val),
        ),
        SwitchListTile(
          title: const Text('With Decoration'),
          value: _withDecoration,
          onChanged: (val) => setState(() => _withDecoration = val),
        ),
        TextField(
          controller: _specialRequestController,
          decoration: const InputDecoration(
            labelText: 'Special Request',
            hintText: 'Any special requirements?',
          ),
        ),
      ],
    );
  }

  Widget _bookTab(Map<String, dynamic> carData, ThemeData theme) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(_selectedDate == null ? 'Select Date' : _selectedDate.toString()),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) setState(() => _selectedTime = picked);
          },
        ),
        const SizedBox(height: 16),
        isBooking
          ? Center(child: CircularProgressIndicator())
          : FilledButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirm Booking'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
          ),
              onPressed: () async {
            if (_selectedDate == null || _selectedTime == null) {
              setState(() { _bookingError = 'Please select date and time.'; });
              return;
            }
            setState(() { isBooking = true; _bookingError = null; });
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw Exception('Not logged in');
                  final bookingData = {
                'userId': user.uid,
                'carName': carData['name'],
                'carImage': carData['image'],
                'date': _selectedDate!.toIso8601String(),
                'time': _selectedTime!.format(context),
                'withDriver': _withDriver,
                'withDecoration': _withDecoration,
                'specialRequest': _specialRequestController.text.trim(),
                'createdAt': DateTime.now().toIso8601String(),
                    'status': 'PENDING',
                  };
                  final docRef = await FirebaseFirestore.instance.collection('bookings').add(bookingData);
              setState(() { isBooking = false; });
                  Navigator.pushReplacementNamed(
                    context,
                    '/booking_confirmation_screen',
                    arguments: {...bookingData, 'id': docRef.id},
                  );
            } catch (e) {
              setState(() { isBooking = false; _bookingError = 'Booking failed. Please try again.'; });
            }
          },
        ),
        if (_bookingError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(_bookingError!, style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}

// Add new Booking Stepper widget at the end of the file
class _BookingStepper extends StatefulWidget {
  final Map<String, dynamic> carData;
  const _BookingStepper({required this.carData});
  @override
  State<_BookingStepper> createState() => _BookingStepperState();
}

class _BookingStepperState extends State<_BookingStepper> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _withDriver = false;
  bool _withDecoration = false;
  final TextEditingController _specialRequestController = TextEditingController();
  bool _isBooking = false;
  String? _error;

  @override
  void dispose() {
    _specialRequestController.dispose();
    super.dispose();
  }

  bool get _dateTimeValid => _selectedDate != null && _selectedTime != null;
  bool get _canBook => _dateTimeValid;

  double _calculateTotal() {
    double basePrice = double.tryParse(widget.carData['price'].toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    double total = basePrice;
    
    if (_withDriver) total += 20;
    if (_withDecoration) total += 15;
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep == 0) {
            if (!_dateTimeValid) {
              setState(() => _error = 'Please select date and time.');
              return;
            }
            setState(() { _error = null; _currentStep++; });
          } else if (_currentStep == 1) {
            setState(() { _currentStep++; });
          } else if (_currentStep == 2) {
            // Submit booking
            setState(() { _isBooking = true; _error = null; });
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw Exception('Not logged in');
              final bookingData = {
                'userId': user.uid,
                'carName': widget.carData['name'],
                'carImage': widget.carData['image'],
                'date': _selectedDate!.toIso8601String(),
                'time': _selectedTime!.format(context),
                'withDriver': _withDriver,
                'withDecoration': _withDecoration,
                'specialRequest': _specialRequestController.text.trim(),
                'createdAt': DateTime.now().toIso8601String(),
                'status': 'PENDING',
              };
              final docRef = await FirebaseFirestore.instance.collection('bookings').add(bookingData);
              setState(() { _isBooking = false; });
              Navigator.pop(context); // Close modal
              Navigator.pushReplacementNamed(
                context,
                '/booking_confirmation_screen',
                arguments: {...bookingData, 'id': docRef.id},
              );
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': user.uid,
                'title': 'Booking Created',
                'message': 'Your booking for ${widget.carData['name']} on ${_selectedDate!.toIso8601String()} has been created and is pending.',
                'timestamp': FieldValue.serverTimestamp(),
                'readBy': [],
              });
              // Admin notification
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': null,
                'title': 'New Booking Request',
                'message': 'A new booking for ${widget.carData['name']} on ${_selectedDate!.toIso8601String()} has been made by a user.',
                'timestamp': FieldValue.serverTimestamp(),
                'readBy': [],
              });
            } catch (e) {
              setState(() { _isBooking = false; _error = 'Booking failed. Please try again.'; });
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
          else Navigator.pop(context);
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (_currentStep < 2)
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Next'),
                ),
              if (_currentStep == 2)
                FilledButton(
                  onPressed: _isBooking ? null : details.onStepContinue,
                  child: _isBooking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirm Booking'),
                ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: details.onStepCancel,
                child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Select Date & Time'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null ? 'Select Date' : _selectedDate.toString().split(' ')[0]),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Customize'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text('With Driver'),
                  value: _withDriver,
                  onChanged: (val) => setState(() => _withDriver = val),
                ),
                SwitchListTile(
                  title: const Text('With Decoration'),
                  value: _withDecoration,
                  onChanged: (val) => setState(() => _withDecoration = val),
                ),
                TextField(
                  controller: _specialRequestController,
                  decoration: const InputDecoration(
                    labelText: 'Special Request',
                    hintText: 'Any special requirements?',
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Review & Payment'),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: Column(
              children: [
                Card(
                  color: theme.colorScheme.surfaceVariant,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: widget.carData['image'].toString().startsWith('http')
                                  ? Image.network(widget.carData['image'], height: 60, width: 90, fit: BoxFit.cover)
                                  : Image.asset(widget.carData['image'], height: 60, width: 90, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.carData['name'], style: theme.textTheme.titleLarge),
                                  Text(widget.carData['price'], style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Date: ${_selectedDate != null ? _selectedDate.toString().split(' ')[0] : '-'}'),
                        Text('Time: ${_selectedTime != null ? _selectedTime!.format(context) : '-'}'),
                        Text('Duration: ${widget.carData['duration'] ?? 1} hour(s)'),
                        Text('With Driver: ${_withDriver ? 'Yes (+\$20)' : 'No'}'),
                        Text('With Decoration: ${_withDecoration ? 'Yes (+\$15)' : 'No'}'),
                        if (_specialRequestController.text.trim().isNotEmpty)
                          Text('Special Request: ${_specialRequestController.text.trim()}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '\$${_calculateTotal().toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/payment_screen',
                      arguments: {
                        'bookingData': {
                          'carId': widget.carData['id'],
                          'carName': widget.carData['name'],
                          'date': _selectedDate?.toIso8601String(),
                          'time': _selectedTime?.format(context),
                          'duration': widget.carData['duration'] ?? 1,
                          'withDriver': _withDriver,
                          'withDecoration': _withDecoration,
                          'specialRequest': _specialRequestController.text.trim(),
                        },
                        'amount': _calculateTotal(),
                      },
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Proceed to Payment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
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