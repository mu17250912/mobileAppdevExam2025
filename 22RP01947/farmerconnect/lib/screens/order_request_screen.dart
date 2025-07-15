import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class OrderRequestScreen extends StatefulWidget {
  final Product product;
  const OrderRequestScreen({super.key, required this.product});

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _delivery = 'Select delivery method';
  int _total = 0;
  bool _isLoading = false;

  void _updateTotal() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _total = qty * widget.product.price;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final order = {
          'productId': widget.product.id,
          'productName': widget.product.name,
          'buyerId': 'current_user_id', // TODO: Get from auth
          'buyerName': 'Marie Uwimana', // TODO: Get from user profile
          'buyerPhone': '+250 788 987 654', // TODO: Get from user profile
          'quantity': int.parse(_quantityController.text),
          'total': _total,
          'delivery': _delivery,
          'notes': _notesController.text,
          'status': 'Pending',
          'createdAt': DateTime.now().toIso8601String(),
          'farmerId': 'farmer_id', // TODO: Get from product
          'farmerName': widget.product.farmerName,
          'farmerPhone': widget.product.farmerPhone,
        };

        await FirestoreService.addOrder(order);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting order: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  color: Color(0xFF2E8B57),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Price: ${widget.product.price} RWF/${widget.product.unit}'),
              const SizedBox(height: 15),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity Needed (kg)'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateTotal(),
                validator: (v) => v == null || v.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _delivery == 'Select delivery method' ? null : _delivery,
                decoration: const InputDecoration(labelText: 'Delivery Preference'),
                items: const [
                  DropdownMenuItem(value: 'Pickup from farm', child: Text('Pickup from farm')),
                  DropdownMenuItem(value: 'Drop-off delivery', child: Text('Drop-off delivery')),
                ],
                onChanged: (v) {
                  setState(() {
                    _delivery = v!;
                  });
                },
                validator: (v) => v == null || v == 'Select delivery method' ? 'Select delivery method' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Additional Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Estimate: $_total RWF', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Final price confirmed by farmer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Order Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 