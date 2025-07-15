import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/premium_service.dart';
import 'services/analytics_service.dart';
import 'services/error_reporting_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'Fertilizers';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Fertilizers',
    'Seeds',
    'Pesticides',
    'Tools',
    'Machinery',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = (widget.product!['name'] ?? '').toString();
      _descriptionController.text = (widget.product!['description'] ?? '').toString();
      _priceController.text = (widget.product!['price'] ?? 0).toString();
      _stockController.text = (widget.product!['stock'] ?? 0).toString();
      _minStockController.text = (widget.product!['minStock'] ?? 5).toString();
      _imageUrlController.text = (widget.product!['imageUrl'] ?? '').toString();
      _selectedCategory = (widget.product!['category'] ?? 'Fertilizers').toString();
    } else {
      _minStockController.text = '5';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    // Robust validation for required fields
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Product name is required.';
      });
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Product description is required.';
      });
      return;
    }
    if (double.tryParse(_priceController.text) == null || double.parse(_priceController.text) <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid price greater than 0.';
      });
      return;
    }
    if (_imageUrlController.text.trim().isNotEmpty && !_imageUrlController.text.trim().startsWith('http')) {
      setState(() {
        _errorMessage = 'Image URL must start with http or https.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Check if user can add more products (for premium service)
      if (widget.product == null) { // Only check for new products
        final canAdd = await PremiumService.canAddProduct(currentUser);
        if (!canAdd) {
          throw Exception('Product limit reached. Please upgrade to premium to add more products.');
        }
      }

      final productData = {
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'No name',
        'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : 'No description',
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'minStock': int.tryParse(_minStockController.text) ?? 5,
        'imageUrl': _imageUrlController.text.trim().isNotEmpty && _imageUrlController.text.trim().startsWith('http')
            ? _imageUrlController.text.trim() 
            : 'https://via.placeholder.com/300x200?text=Product+Image',
        'category': _selectedCategory.isNotEmpty ? _selectedCategory : 'General',
        'dealer': currentUser,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.product != null) {
        // Update existing product
        final docRef = FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product!['id']);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.update(productData);
        } else {
          await docRef.set(productData);
        }
        await AnalyticsService.trackProductUpdate(
          productId: widget.product!['id'],
          productName: _nameController.text.trim(),
          dealer: currentUser,
        );
      } else {
        // Add new product
        final docRef = await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
        
        await AnalyticsService.trackProductAdd(
          productId: docRef.id,
          productName: _nameController.text.trim(),
          dealer: currentUser,
          category: _selectedCategory,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null 
                  ? 'Product updated successfully!' 
                  : 'Product added successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      await ErrorReportingService.reportError(
        errorType: 'product_save_error',
        errorMessage: 'Failed to save product',
        error: e,
        additionalData: {
          'action': widget.product != null ? 'update' : 'add',
          'productName': _nameController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Stock cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Stock *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter minimum stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Minimum stock cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.product != null ? 'Update Product' : 'Add Product',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 