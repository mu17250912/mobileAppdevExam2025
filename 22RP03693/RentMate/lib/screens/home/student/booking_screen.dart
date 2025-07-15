import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/property.dart';
import '../../../models/booking.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/theme.dart';
import '../../../providers/booking_provider.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Property property;

  const BookingScreen({
    super.key,
    required this.property,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _selectedMonths = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.property.monthlyRent * _selectedMonths;
    final depositAmount = widget.property.monthlyRent * 0.5; // 50% deposit

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Property'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Summary
              _buildPropertySummary(),
              const SizedBox(height: 24),
              // Date Selection
              _buildDateSelection(),
              const SizedBox(height: 24),
              // Duration Selection
              _buildDurationSelection(),
              const SizedBox(height: 24),
              // Message to Landlord
              _buildMessageSection(),
              const SizedBox(height: 24),
              // Payment Summary
              _buildPaymentSummary(totalAmount, depositAmount),
              const SizedBox(height: 32),
              // Book Button
              CustomButton(
                text: 'Book Now',
                onPressed: _isLoading ? null : () => _submitBooking(depositAmount),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: widget.property.images.isNotEmpty
                    ? Image.network(
                        widget.property.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.home),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.home),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Property Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.property.monthlyRent.toStringAsFixed(0)}/month',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Dates',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Check-in Date',
                _checkInDate,
                Icons.calendar_today,
                () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                'Check-out Date',
                _checkOutDate,
                Icons.calendar_today,
                () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
                    : 'Select date',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Duration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of Months',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$_selectedMonths month${_selectedMonths > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _selectedMonths.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '$_selectedMonths month${_selectedMonths > 1 ? 's' : ''}',
                  onChanged: (value) {
                    setState(() {
                      _selectedMonths = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message to Landlord',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _messageController,
          label: 'Optional message',
          hint: 'Tell the landlord about your requirements...',
          maxLines: 4,
          prefixIcon: Icons.message_outlined,
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(double totalAmount, double depositAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPaymentRow('Monthly Rent', 'RWF ${widget.property.monthlyRent.toStringAsFixed(0)}'),
                _buildPaymentRow('Duration', '$_selectedMonths month${_selectedMonths > 1 ? 's' : ''}'),
                _buildPaymentRow('Total Rent', 'RWF ${totalAmount.toStringAsFixed(0)}'),
                const Divider(),
                _buildPaymentRow(
                  'Deposit Required',
                  'RWF ${depositAmount.toStringAsFixed(0)}',
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will be charged the deposit amount now. The remaining amount will be due before move-in.',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Set checkout date to 1 month after check-in
          _checkOutDate = picked.add(Duration(days: 30 * _selectedMonths));
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _submitBooking(double depositAmount) async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = _messageController.text.trim();
      // Add booking to the booking provider
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.addBooking(widget.property, message: message);

      // Create booking object for payment screen
      final booking = Booking(
        property: widget.property,
        status: 'Pending',
        date: DateTime.now(),
        message: message,
      );

      // Navigate to payment screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              booking: booking,
              amount: depositAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 