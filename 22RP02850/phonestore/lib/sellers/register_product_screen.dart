import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/notification_service.dart';
import '../sellers/seller_home.dart';
import '../sellers/manage_products_screen.dart';
import '../sellers/seller_chats_screen.dart';

class RegisterProductScreen extends StatefulWidget {
  const RegisterProductScreen({super.key});

  @override
  State<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends State<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;
  String? _cloudinaryImageUrl;
  bool _showSuccessBanner = false;

  void _showBanner() {
    setState(() {
      _showSuccessBanner = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessBanner = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cloudinaryImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final stock = int.tryParse(_stockController.text) ?? 0;
      final product = Product(
        id: '',
        name: _nameController.text,
        price: double.parse(_priceController.text),
        imageUrl: _cloudinaryImageUrl!,
        sellerId: user.uid,
        description: _descriptionController.text,
        stock: stock,
        inStock: stock > 0,
      );
      final docRef = await FirebaseFirestore.instance.collection('products').add(product.toMap());
      
      // Log analytics event for adding a product
      await FirebaseAnalytics.instance.logEvent(
        name: 'add_product',
        parameters: {
          'seller_id': user.uid,
          'product_name': _nameController.text,
          'price': double.parse(_priceController.text),
        },
      );
      
      // Send notification to all clients about new product
      await NotificationService.sendNotificationToAllUsers(
        title: 'New Product Available!',
        body: '${product.name} is now available for £${product.price.toStringAsFixed(2)}',
        type: 'new_product',
        data: {
          'productId': docRef.id,
          'productName': product.name,
          'price': product.price,
        },
      );
      
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _stockController.clear();
      setState(() {
        _cloudinaryImageUrl = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Helper for logging purchase events (for future use)
Future<void> logPurchaseEvent({
  required String buyerId,
  required String productId,
  required double amount,
}) async {
  await FirebaseAnalytics.instance.logEvent(
    name: 'purchase',
    parameters: {
      'buyer_id': buyerId,
      'product_id': productId,
      'amount': amount,
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please login to register products'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }
    // Remove Scaffold, just return the form content
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildRegisterForm(context, user),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, User user) {
    return Card(
      elevation: 16,
      shadowColor: Colors.purple.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _stockController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Image',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ProductImageUploader(
                          onImageUploaded: (url) {
                            setState(() {
                              _cloudinaryImageUrl = url;
                            });
                          },
                          uploadedImageUrl: _cloudinaryImageUrl,
                        ),
                        if (_cloudinaryImageUrl == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Upload a product image',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          await _addProduct();
                          _showBanner();
                        },
                        child: const Text('Add Product'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImageUploader extends StatefulWidget {
  final Function(String) onImageUploaded;
  final String? uploadedImageUrl;
  const ProductImageUploader({required this.onImageUploaded, this.uploadedImageUrl, super.key});

  @override
  State<ProductImageUploader> createState() => _ProductImageUploaderState();
}

class _ProductImageUploaderState extends State<ProductImageUploader> {
  File? _image;
  Uint8List? _webImageBytes;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });

    String? filePath;
    Uint8List? fileBytes;

    if (kIsWeb) {
      // Use file_picker for web
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null) {
        setState(() => _isUploading = false);
        return;
      }
      fileBytes = result.files.single.bytes;
      if (fileBytes == null) {
        setState(() => _isUploading = false);
        return;
      }
      _webImageBytes = fileBytes;
    } else {
      // Use image_picker for mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        setState(() => _isUploading = false);
        return;
      }
      filePath = pickedFile.path;
      _image = File(filePath);
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/dfofgjnys/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'Images';

    if (kIsWeb && fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: 'upload.png',
        ),
      );
    } else if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      setState(() {
        _isUploading = false;
      });
      widget.onImageUploaded(data['secure_url']);
    } else {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (widget.uploadedImageUrl != null) {
      imageWidget = Image.network(widget.uploadedImageUrl!, height: 120);
    } else if (kIsWeb && _webImageBytes != null) {
      imageWidget = Image.memory(_webImageBytes!, height: 120);
    } else if (_image != null) {
      imageWidget = Image.file(_image!, height: 120);
    } else {
      imageWidget = Container(
        height: 120,
        width: 120,
        color: Colors.grey[300],
        child: Icon(Icons.image, size: 60, color: Colors.grey[700]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Product Image", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        imageWidget,
        SizedBox(height: 8),
        _isUploading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: Icon(Icons.cloud_upload),
                label: Text("Upload Image"),
                onPressed: _pickAndUploadImage,
              ),
      ],
    );
  }
} 