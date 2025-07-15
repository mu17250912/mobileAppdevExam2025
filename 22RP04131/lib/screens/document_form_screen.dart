import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../utils/document_calculator.dart';

class DocumentFormScreen extends StatefulWidget {
  final Document? document;
  const DocumentFormScreen({Key? key, this.document}) : super(key: key);

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _discountController;

  List<_Item> items = [];
  List<TextEditingController> _itemNameControllers = [];
  List<TextEditingController> _itemQtyControllers = [];
  List<TextEditingController> _itemPriceControllers = [];
  bool vatEnabled = true;
  double calculatedTotal = 0.0;
  double calculatedVAT = 0.0;
  double calculatedDiscount = 0.0;
  double calculatedSubtotal = 0.0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      // Pre-fill fields from the document
      _clientNameController = TextEditingController(text: widget.document!.clientInfo.name);
      _clientEmailController = TextEditingController(text: widget.document!.clientInfo.email ?? '');
      _clientPhoneController = TextEditingController(text: widget.document!.clientInfo.phone ?? '');
      _discountController = TextEditingController(text: widget.document!.discount.toString());
      items = widget.document!.items.map((e) => _Item(name: e.name, quantity: e.quantity, price: e.price)).toList();
      // Optionally pre-fill VAT, etc.
    } else {
      _clientNameController = TextEditingController();
      _clientEmailController = TextEditingController();
      _clientPhoneController = TextEditingController();
      _discountController = TextEditingController();
      items = [];
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _discountController.dispose();
    for (final c in _itemNameControllers) { c.dispose(); }
    for (final c in _itemQtyControllers) { c.dispose(); }
    for (final c in _itemPriceControllers) { c.dispose(); }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      items.add(_Item(name: '', quantity: 1, price: 0.0));
      _itemNameControllers.add(TextEditingController());
      _itemQtyControllers.add(TextEditingController(text: '1'));
      _itemPriceControllers.add(TextEditingController(text: '0.00'));
      _calculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _itemNameControllers[index].dispose();
      _itemQtyControllers[index].dispose();
      _itemPriceControllers[index].dispose();
      _itemNameControllers.removeAt(index);
      _itemQtyControllers.removeAt(index);
      _itemPriceControllers.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    final docItems = items.map((e) => DocumentItem(name: e.name, quantity: e.quantity, price: e.price, total: e.price * e.quantity)).toList();
    final discountPercent = double.tryParse(_discountController.text) ?? 0.0;
    final result = DocumentCalculator.calculateAll(
      items: docItems,
      discountPercent: discountPercent,
      vatEnabled: vatEnabled,
      vatRate: 0.18,
    );
    setState(() {
      calculatedSubtotal = result['subtotal']!;
      calculatedDiscount = result['discount']!;
      calculatedVAT = result['vat']!;
      calculatedTotal = result['total']!;
    });
  }

  void _submit({bool asDraft = false}) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final isPremium = appState.userProfile?.premium ?? false;
    final docs = await appState.documentsStream().first;
    final docCount = docs.length;
    if (!isPremium && docCount >= 10 && widget.document == null && !asDraft) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text('Free users can only create up to 10 documents. Upgrade to premium for unlimited document creation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Optionally navigate to settings or show upgrade dialog
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false && items.isNotEmpty) {
      setState(() {
        _loading = true;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final docItems = items.map((e) => DocumentItem(name: e.name, quantity: e.quantity, price: e.price, total: e.price * e.quantity)).toList();
      final discountPercent = double.tryParse(_discountController.text) ?? 0.0;
      try {
        if (widget.document != null) {
          // Update existing document
          final updatedDoc = widget.document!.copyWith(
            clientInfo: widget.document!.clientInfo.copyWith(
              name: _clientNameController.text.trim(),
              email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
              phone: _clientPhoneController.text.trim().isEmpty ? null : _clientPhoneController.text.trim(),
            ),
            items: docItems,
            subtotal: calculatedSubtotal,
            discount: calculatedDiscount,
            vatRate: 0.18,
            vatAmount: calculatedVAT,
            total: calculatedTotal,
            status: asDraft ? DocumentStatus.draft : DocumentStatus.pending,
          );
          await appState.updateDocument(updatedDoc);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(asDraft ? 'Draft updated!' : 'Document updated!'),
              backgroundColor: asDraft ? Colors.orange : Colors.green,
            ),
          );
          context.go('/dashboard');
        } else {
          // Create new document
          final newDoc = await appState.createDocument(
            type: _getDocTypeFromRoute(),
            clientInfo: ClientInfo(
              name: _clientNameController.text.trim(),
              email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
              phone: _clientPhoneController.text.trim().isEmpty ? null : _clientPhoneController.text.trim(),
            ),
            items: docItems,
            subtotal: calculatedSubtotal,
            discount: calculatedDiscount,
            vatRate: 0.18,
            vatAmount: calculatedVAT,
            total: calculatedTotal,
            status: asDraft ? DocumentStatus.draft : DocumentStatus.pending,
            createdDate: DateTime.now(),
            dueDate: null,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(asDraft ? 'Draft saved!' : 'Document created successfully!'),
              backgroundColor: asDraft ? Colors.orange : Colors.green,
            ),
          );
          if (asDraft) {
            context.go('/dashboard');
          } else if (newDoc != null) {
            context.go('/document-preview?id=${newDoc.id}');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _loading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and add at least one item.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  DocumentType _getDocTypeFromRoute() {
    final typeStr = GoRouterState.of(context).queryParams['type'];
    switch (typeStr) {
      case 'quote':
        return DocumentType.quote;
      case 'deliveryNote':
        return DocumentType.deliveryNote;
      case 'proforma':
        return DocumentType.proforma;
      default:
        return DocumentType.invoice;
    }
  }

  String _docTypeName() {
    final type = _getDocTypeFromRoute();
    switch (type) {
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.quote:
        return 'Quote';
      case DocumentType.deliveryNote:
        return 'Delivery Note';
      case DocumentType.proforma:
        return 'Proforma';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.green100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create ${_docTypeName()} ', style: AppTypography.titleMedium),
        actions: [
          TextButton(
            onPressed: () => _submit(asDraft: true),
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
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.phone,
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _ItemFormWidget(
                          nameController: _itemNameControllers[i],
                          qtyController: _itemQtyControllers[i],
                          priceController: _itemPriceControllers[i],
                          onChanged: (item) {
                            setState(() {
                              items[i] = item;
                              _calculateTotal();
                            });
                          },
                          onRemove: () => _removeItem(i),
                        ),
                      ),
                    ],
                  ),
                ),
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
                          const Text('Add VAT (18%)', style: AppTypography.bodyLarge),
                          Switch(
                            value: vatEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() {
                              vatEnabled = v;
                              _calculateTotal();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          labelText: 'Discount (%)',
                          hintText: 'Enter discount percentage',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateTotal(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.green100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: AppTypography.titleLarge),
                      Text('RWF ${calculatedTotal.toStringAsFixed(2)}', style: AppTypography.headlineMedium.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.labelLarge,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Generate PDF'),
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

class _ItemFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final ValueChanged<_Item> onChanged;
  final VoidCallback onRemove;
  const _ItemFormWidget({required this.nameController, required this.qtyController, required this.priceController, required this.onChanged, required this.onRemove, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Item name'),
              onChanged: (v) => onChanged(_Item(name: v, quantity: int.tryParse(qtyController.text) ?? 1, price: double.tryParse(priceController.text) ?? 0.0)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: qtyController,
              decoration: const InputDecoration(hintText: 'Qty'),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged(_Item(name: nameController.text, quantity: int.tryParse(v) ?? 1, price: double.tryParse(priceController.text) ?? 0.0)),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min 1' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: priceController,
              decoration: const InputDecoration(hintText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged(_Item(name: nameController.text, quantity: int.tryParse(qtyController.text) ?? 1, price: double.tryParse(v) ?? 0.0)),
              validator: (v) => (double.tryParse(v ?? '') ?? 0.0) < 0.01 ? 'Min 0.01' : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
} 