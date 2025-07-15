import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../services/print_service.dart';
import '../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _customerController = TextEditingController();
  
  String? _selectedProduct;
  String? _selectedPaymentMethod;
  String? _selectedCustomer;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  
  final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
  final FirestoreService _firestoreService = FirestoreService();
  final PrintService _printService = PrintService();
  
  final List<String> _paymentMethods = ['Cash', 'Mobile Money', 'Credit', 'Bank Transfer'];

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _firestoreService.getProductsStream().listen((products) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    });
  }

  void _calculateTotal() {
    if (_selectedProduct != null && _quantityController.text.isNotEmpty) {
      final product = _products.firstWhere((p) => p['name'] == _selectedProduct);
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final total = product['price'] * quantity;
      _priceController.text = total.toString();
    }
  }

  Future<void> _recordSale() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get selected product data
      final selectedProduct = _products.firstWhere((p) => p['name'] == _selectedProduct);
      final quantity = int.parse(_quantityController.text);
      final totalAmount = int.parse(_priceController.text);
      
      // Create sale record
      final saleData = {
        'productId': selectedProduct['id'],
        'productName': selectedProduct['name'],
        'quantity': quantity,
        'unitPrice': selectedProduct['price'],
        'totalAmount': totalAmount,
        'paymentMethod': _selectedPaymentMethod,
        'customerName': _customerController.text.isNotEmpty ? _customerController.text : 'Walk-in',
        'customerId': _selectedCustomer,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestoreService.addSale(saleData);

      setState(() {
        _isProcessing = false;
      });

      // Show success dialog with print option
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text('Sale Recorded!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product: $_selectedProduct'),
                Text('Quantity: ${_quantityController.text}'),
                Text('Total: ${_priceController.text} RWF'),
                Text('Payment: $_selectedPaymentMethod'),
                if (_customerController.text.isNotEmpty)
                  Text('Customer: ${_customerController.text}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await _printService.printSalesReceipt(saleData);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error printing receipt: $e')),
                    );
                  }
                },
                child: Text('Print Receipt'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: Text('Record Another'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                child: Text('Done', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording sale: $e')),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedProduct = null;
      _selectedPaymentMethod = null;
    });
    _productController.clear();
    _quantityController.clear();
    _priceController.clear();
    _customerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recordSale),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Recent Sales'),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.receipt, color: mainColor),
                          title: Text('Sale #${1000 + index}'),
                          subtitle: Text('${_products[index % _products.length]['name']} - ${_products[index % _products.length]['price']} RWF'),
                          trailing: Text('${DateTime.now().subtract(Duration(hours: index + 1)).hour}:00'),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainColor))
          : _products.isEmpty
              ? Center(child: Text('No products available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Selection
                        Text(AppLocalizations.of(context)!.selectProduct, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedProduct,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.shopping_bag, color: mainColor),
                            labelText: AppLocalizations.of(context)!.chooseProduct,
                          ),
                          items: _products.map((product) {
                            return DropdownMenuItem<String>(
                              value: product['name'],
                              child: Text('${product['name']} - ${product['price']} RWF (Stock: ${product['stock']})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProduct = value;
                            });
                            _calculateTotal();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a product';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Quantity
                        Text(AppLocalizations.of(context)!.quantity, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.numbers, color: mainColor),
                            labelText: AppLocalizations.of(context)!.enterQuantity,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) => _calculateTotal(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Total Price (Auto-calculated)
                        Text('Total Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.attach_money, color: mainColor),
                            labelText: 'Total Amount (RWF)',
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          readOnly: true,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Customer Name (Optional)
                        Text('Customer Name (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _customerController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.person, color: mainColor),
                            labelText: 'Customer Name',
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Payment Method
                        Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.payment, color: mainColor),
                            labelText: 'Select Payment Method',
                          ),
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem(value: method, child: Text(method));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select payment method';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Record Sale Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            icon: _isProcessing 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Icon(Icons.check),
                            label: Text(_isProcessing ? 'Recording Sale...' : 'Record Sale'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isProcessing ? null : _recordSale,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Quick Actions
                        Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.clear),
                                label: Text(AppLocalizations.of(context)!.clearForm),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: _resetForm,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.inventory),
                                label: Text('Check Stock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pushNamed(context, '/inventory'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 