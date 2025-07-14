import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import '../../models/event_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../services/event_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEventId;
  String _method = 'momo';
  final _amountController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final double _fixedCharges = 1000.0;
  bool _isLoading = false;

  static const List<Map<String, String>> paymentMethods = [
    {'value': 'momo', 'label': 'Mobile Money'},
    {'value': 'card', 'label': 'Credit/Debit Card'},
    {'value': 'paypal', 'label': 'PayPal'},
    {'value': 'cash', 'label': 'Cash'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _fullNameController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    // Only show events created by the current user, always up-to-date
    final userEvents = eventProvider.events.where((event) => event.organizerId == authProvider.currentUser?.uid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEventId,
                items: userEvents.map((event) {
                  return DropdownMenuItem(
                    value: event.id,
                    child: Text(event.title),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedEventId = val),
                decoration: const InputDecoration(
                  labelText: 'Select Event',
                ),
                validator: (val) => val == null ? 'Please select an event' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (RWF)',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone Number',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter your telephone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                initialValue: _fixedCharges.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Charges (RWF)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _method,
                items: paymentMethods.map((method) => DropdownMenuItem(
                  value: method['value'],
                  child: Text(method['label']!),
                )).toList(),
                onChanged: (val) => setState(() => _method = val ?? 'momo'),
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isLoading = true);
                          try {
                            // Simulate payment processing
                            await Future.delayed(const Duration(seconds: 2));
                            final enteredAmount = double.parse(_amountController.text);
                            final ussdCharge = _fixedCharges;
                            final netAmount = enteredAmount - ussdCharge;
                            if (netAmount <= 0) throw 'Amount must be greater than $_fixedCharges RWF';
                            final payment = PaymentModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: authProvider.currentUser!.uid,
                              eventId: _selectedEventId,
                              amount: netAmount,
                              currency: 'RWF',
                              status: 'completed',
                              method: _method,
                              fullName: _fullNameController.text.trim(),
                              telephone: _telephoneController.text.trim(),
                              charges: ussdCharge,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await paymentProvider.createPayment(payment);
                            // Approve the event after payment
                            if (_selectedEventId != null) {
                              await EventService.updateEventStatus(_selectedEventId!, 'confirmed');
                            }
                            // Save notification in Firestore
                            await NotificationService.saveNotification(
                              userId: authProvider.currentUser!.uid,
                              title: 'Payment Successful',
                              message: 'You paid $netAmount RWF for event.',
                            );
                            NotificationService.showSuccessNotification(
                              title: 'Payment Successful',
                              message: 'Your payment was recorded. USSD charge: $_fixedCharges RWF',
                            );
                            Get.back();
                          } catch (e) {
                            NotificationService.showErrorNotification(
                              title: 'Payment Failed',
                              message: e.toString(),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pay Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 