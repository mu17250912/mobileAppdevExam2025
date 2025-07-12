import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';

class FormValidationErrorScreen extends StatefulWidget {
  const FormValidationErrorScreen({Key? key}) : super(key: key);

  @override
  State<FormValidationErrorScreen> createState() => _FormValidationErrorScreenState();
}

class _FormValidationErrorScreenState extends State<FormValidationErrorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  List<_Item> items = [];
  bool vatEnabled = true;
  double calculatedTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Add a sample item with errors
    items.add(_Item(name: 'Web Development', quantity: 1, price: 0.0));
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      items.add(_Item(name: '', quantity: 1, price: 0.0));
      _calculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    double afterDiscount = subtotal - (subtotal * (discount / 100));
    double vat = vatEnabled ? afterDiscount * 0.18 : 0.0;
    setState(() {
      calculatedTotal = afterDiscount + vat;
    });
  }

  void _onItemChanged() {
    _calculateTotal();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Save document and navigate to preview
      context.go('/document-preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.red50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Create Invoice', style: AppTypography.titleMedium),
        actions: [
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  border: Border.all(color: AppColors.red300, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Please fix the following errors:', style: AppTypography.bodyLarge),
                          const SizedBox(height: 4),
                          const Text('• Client name is required\n• At least one item must be added\n• Item price cannot be empty', style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Client Information', style: AppTypography.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          labelText: 'Client Name',
                          hintText: 'Enter client name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)),
                          fillColor: AppColors.red50,
                          filled: true,
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Client name is required' : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.error, size: 12, color: AppColors.error),
                            const SizedBox(width: 4),
                            const Text('Client name is required', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientEmailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items', style: AppTypography.titleMedium),
                          TextButton(
                            onPressed: _addItem,
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTypography.bodyMedium),
                            child: const Text('+ Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.error, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: 'Web Development',
                              decoration: const InputDecoration(
                                hintText: 'Item name',
                                border: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '1',
                                    decoration: InputDecoration(
                                      hintText: 'Qty',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      hintText: 'Price',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                      fillColor: AppColors.red50,
                                      filled: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: const Text('RWF 0.00', style: AppTypography.bodyMedium),
                                  ),
                                ),
                              ],
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('Required', style: AppTypography.bodySmall),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.labelLarge,
                  ),
                  onPressed: null, // Disabled due to validation errors
                  child: const Text('Generate PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  String name;
  int quantity;
  double price;
  _Item({required this.name, required this.quantity, required this.price});
} 