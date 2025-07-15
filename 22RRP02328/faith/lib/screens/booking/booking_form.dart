import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class BookingForm extends StatefulWidget {
  final UserModel provider;
  final List<EventModel> userEvents;
  const BookingForm({super.key, required this.provider, required this.userEvents});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedEventId;
  String _contactMethod = 'email';
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  final _additionalMessageController = TextEditingController();
  final _priceController = TextEditingController();
  String _place = '';
  String _duration = '1 hour';
  static const List<String> durations = [
    '30 minutes', '1 hour', '2 hours', 'Half-day', 'Full-day'
  ];
  bool _isLoading = false;

  static const List<String> serviceTypes = [
    'Spiritual Counseling',
    'Prayer Request',
    'Event Registration',
    'Premium Support',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _additionalMessageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _fullNameController.text = authProvider.userData?.name ?? '';
    _emailController.text = authProvider.userData?.email ?? '';
    _phoneController.text = authProvider.userData?.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book ${widget.provider.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _contactMethod,
                items: const [
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                ],
                onChanged: (val) => setState(() => _contactMethod = val ?? 'email'),
                decoration: const InputDecoration(labelText: 'Preferred Contact Method'),
              ),
              const SizedBox(height: 12),
              if (_contactMethod == 'email')
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your email' : null,
                ),
              if (_contactMethod == 'phone')
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your phone number' : null,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedEventId,
                items: widget.userEvents.map((event) {
                  return DropdownMenuItem(
                    value: event.id,
                    child: Text(event.title),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEventId = val;
                    final selectedEvent = widget.userEvents.firstWhere((e) => e.id == val, orElse: () => widget.userEvents.first);
                    _place = selectedEvent.location;
                  });
                },
                decoration: const InputDecoration(labelText: 'Select Event'),
                validator: (val) => val == null ? 'Select an event' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (RWF)'),
                validator: (val) => val == null || val.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: false,
                initialValue: _place,
                decoration: const InputDecoration(labelText: 'Place'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _duration,
                items: durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => _duration = val ?? durations[0]),
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _preferredDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Preferred Date'),
                  child: Text(_preferredDate == null ? 'Select date' : '${_preferredDate!.toLocal()}'.split(' ')[0]),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _preferredTime = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Preferred Time'),
                  child: Text(_preferredTime == null ? 'Select time' : _preferredTime!.format(context)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalMessageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Additional Message'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate() || _preferredDate == null || _preferredTime == null) return;
                          setState(() => _isLoading = true);
                          try {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
                            final booking = BookingModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: authProvider.currentUser!.uid,
                              eventId: _selectedEventId!,
                              providerId: widget.provider.id,
                              fullName: _fullNameController.text.trim(),
                              email: _contactMethod == 'email' ? _emailController.text.trim() : '',
                              phone: _contactMethod == 'phone' ? _phoneController.text.trim() : '',
                              serviceType: '',
                              preferredDate: _preferredDate!,
                              preferredTime: _preferredTime!.format(context),
                              additionalMessage: _additionalMessageController.text.trim(),
                              requirements: '',
                              status: 'pending',
                              price: double.tryParse(_priceController.text) ?? 0,
                              place: _place,
                              duration: _duration,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await bookingProvider.createBooking(booking);
                            await NotificationService.saveNotification(
                              userId: authProvider.currentUser!.uid,
                              title: 'Booking Successful',
                              message: 'Your session has been booked successfully. We will contact you shortly.',
                            );
                            // Notify provider
                            await NotificationService.saveNotification(
                              userId: widget.provider.id,
                              title: 'New Booking',
                              message: '${_fullNameController.text.trim()} booked your service for ${_preferredDate!.toLocal().toString().split(' ')[0]} at ${_preferredTime!.format(context)}.',
                            );
                            NotificationService.showSuccessNotification(
                              title: 'Booking Successful',
                              message: 'Your session has been booked successfully. We will contact you shortly.',
                            );
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Booking Successful'),
                                content: const Text('Your session has been booked successfully. We will contact you shortly.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            Get.back();
                          } catch (e) {
                            NotificationService.showErrorNotification(
                              title: 'Booking Failed',
                              message: e.toString(),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 