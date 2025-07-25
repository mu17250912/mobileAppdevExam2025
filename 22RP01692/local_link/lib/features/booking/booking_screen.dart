import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import 'payment_screen.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
  String _selectedServiceType = 'Basic Service';
  String _selectedPaymentMethod = 'Pay Now';
  String _notes = '';
  String _selectedLocation = 'Current Location';
  String _customLocation = '';
  String _contactPhone = '';
  String _contactName = '';
  Map<String, dynamic>? _service;

  final List<String> _serviceTypes = [
    'Basic Service',
    'Standard Service', 
    'Premium Service'
  ];

  final List<String> _paymentMethods = [
    'Pay Now',
    'Pay Later'
  ];

  final List<String> _locations = [
    'Current Location',
    'Home Address',
    'Office Address',
    'Custom Location'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _service = args;
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _goToPayment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateTime != null && _service != null) {
        // Save booking to Firestore
        _saveBooking();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              service: _service!,
              dateTime: _selectedDateTime!,
              serviceType: _selectedServiceType,
              paymentMethod: _selectedPaymentMethod,
              notes: _notes,
              location: _selectedLocation == 'Custom Location' ? _customLocation : _selectedLocation,
            ),
          ),
        );
      } else if (_selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date and time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveBooking() async {
    final booking = {
      'userId': 'user123',
      'providerId': _service!['id'],
      'date': _selectedDateTime!.toIso8601String(),
      'serviceType': _selectedServiceType,
      'status': 'pending',
      'paymentStatus': _selectedPaymentMethod == 'Pay Now' ? 'paid' : 'unpaid',
      'notes': _notes,
      'location': _selectedLocation == 'Custom Location' ? _customLocation : _selectedLocation,
      'contactName': _contactName,
      'contactPhone': _contactPhone,
    };
    try {
      await FirestoreService().saveBooking(booking);
      print('Booking saved: $booking');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Book Service'),
      body: service == null
          ? const Center(child: Text('No service selected.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              child: Text(
                                service['name'].split(' ').map((e) => e[0]).join(''),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(service['description'], style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Contact Information
                    const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        floatingLabelStyle: const TextStyle(color: Colors.blue),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (value) => _contactName = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        floatingLabelStyle: const TextStyle(color: Colors.blue),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      onChanged: (value) => _contactPhone = value,
                    ),
                    const SizedBox(height: 24),
                    
                    // Service Type Selection
                    const Text('Service Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      items: _serviceTypes.map((type) {
                        return DropdownMenuItem(
                          value: type, 
                          child: Text(type, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date & Time Selection
                    const Text('Date & Time *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _selectedDateTime == null ? Colors.red : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDateTime == null
                                    ? 'Select date and time'
                                    : DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!),
                                style: TextStyle(
                                  color: _selectedDateTime == null ? Colors.grey[600] : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDateTime == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select a date and time',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Location Selection
                    const Text('Service Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location, 
                          child: Text(location, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Custom Location Field
                    if (_selectedLocation == 'Custom Location')
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Custom Address *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.location_on),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          floatingLabelStyle: const TextStyle(color: Colors.blue),
                        ),
                        validator: (value) {
                          if (_selectedLocation == 'Custom Location' && (value == null || value.isEmpty)) {
                            return 'Please enter the address';
                          }
                          return null;
                        },
                        onChanged: (value) => _customLocation = value,
                      ),
                    const SizedBox(height: 16),
                    
                    // Notes Field
                    const Text('Additional Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any special requirements or instructions...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _notes = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method
                    const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method, 
                          child: Text(method, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Proceed Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text(
                          'Proceed to ${_selectedPaymentMethod == 'Pay Now' ? 'Payment' : 'Confirmation'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 