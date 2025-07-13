import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/property.dart';
import '../services/payment_service.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.title),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            if (widget.property.images.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Image.network(
                    widget.property.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.textTertiary.withOpacity(0.1),
                        child: Icon(
                          Icons.home,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: AppSizes.lg),
            
            // Property Title
            Text(
              widget.property.title,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSizes.sm),
            
            // Price
            Text(
              widget.property.formattedPrice,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSizes.lg),
            
            // Property Details
            _buildPropertyDetails(),
            
            const SizedBox(height: AppSizes.lg),
            
            // Description
            Text(
              'Description',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              widget.property.description,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contact Owner Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text('Contact Owner (\$50)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                onPressed: () => _showContactOwnerDialog(context),
              ),
            ),
            
            const SizedBox(height: AppSizes.md),
            
            // Buy Property Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Submit Purchase Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                onPressed: () => _showBuyPropertyForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.bed,
            label: 'Bedrooms',
            value: '${widget.property.bedrooms}',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.bathtub_outlined,
            label: 'Bathrooms',
            value: '${widget.property.bathrooms}',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.square_foot,
            label: 'Area',
            value: widget.property.formattedArea,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyPropertyForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _BuyPropertyForm(property: widget.property),
      ),
    );
  }

  void _showContactOwnerDialog(BuildContext context) {
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
              await _processDirectPayment(context);
            },
            child: const Text('Pay \$50'),
          ),
        ],
      ),
    );
  }

  Future<void> _processDirectPayment(BuildContext context) async {
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
        // Create a direct contact request in Firestore
        await FirebaseFirestore.instance.collection('direct_contacts').add({
          'propertyId': widget.property.id,
          'propertyTitle': widget.property.title,
          'buyerName': user.fullName,
          'buyerEmail': user.email,
          'buyerPhone': user.phone,
          'paymentStatus': 'paid',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful!'),
              content: const Text(
                'Your payment has been processed successfully. '
                'The commissioner will connect you with the property owner within 24 hours.',
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

class _BuyPropertyForm extends StatefulWidget {
  final Property property;
  const _BuyPropertyForm({Key? key, required this.property}) : super(key: key);

  @override
  State<_BuyPropertyForm> createState() => _BuyPropertyFormState();
}

class _BuyPropertyFormState extends State<_BuyPropertyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _offerController = TextEditingController();
  final _messageController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _moveInDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _offerController.dispose();
    _messageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Buy ${widget.property.title}',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Your Name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Contact (Email or Phone)'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your contact info';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
              final phoneRegex = RegExp(r'^[0-9+\-() ]{7,}$');
              if (!emailRegex.hasMatch(v) && !phoneRegex.hasMatch(v)) {
                return 'Enter a valid email or phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Your Address'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your address' : null,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _moveInDate = picked);
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Preferred Move-in Date',
                  hintText: 'Select date',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (v) => _moveInDate == null ? 'Please select a move-in date' : null,
                controller: TextEditingController(
                  text: _moveInDate == null ? '' : DateFormat.yMMMMd().format(_moveInDate!),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _offerController,
            decoration: const InputDecoration(labelText: 'Offer Amount'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your offer';
              final num? offer = num.tryParse(v);
              if (offer == null || offer <= 0) return 'Enter a valid offer amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('purchase_requests').add({
        'propertyId': widget.property.id,
        'propertyTitle': widget.property.title,
        'buyerName': _nameController.text.trim(),
        'buyerContact': _contactController.text.trim(),
        'buyerAddress': _addressController.text.trim(),
        'moveInDate': _moveInDate != null ? Timestamp.fromDate(_moveInDate!) : null,
        'timestamp': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending',
        'status': 'pending',
      });
      
      // Create notification for commissioner
      await NotificationService.createPurchaseRequestNotification(
        requestId: docRef.id,
        buyerName: _nameController.text.trim(),
        propertyTitle: widget.property.title,
        offer: _offerController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            content: const Text(
              'Your purchase request has been submitted! The seller or agent will contact you soon.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
} 