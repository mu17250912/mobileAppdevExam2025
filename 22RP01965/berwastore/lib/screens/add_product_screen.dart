import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String price = '';
  String category = '';
  String size = '';
  File? _imageFile;
  String? _selectedAssetImage;
  bool _loading = false;

  final List<String> assetImages = [
    'assets/images/nike_air_max.png',
    'assets/images/cotton_tshirt.png',
    'assets/images/Denim_jeans.png',
    'assets/images/summer_dress.png',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _selectedAssetImage = null; // Clear asset if file is chosen
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.path.split('/').last;
      final ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    String? imageUrl;
    if (_selectedAssetImage != null) {
      imageUrl = _selectedAssetImage;
    } else if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')),
        );
        setState(() => _loading = false);
        return;
      }
    }
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'category': category,
        'size': size,
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.pop(context); // Go back to dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Product Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: assetImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final asset = assetImages[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAssetImage = asset;
                            _imageFile = null; // Clear file if asset is chosen
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedAssetImage == asset ? Colors.blue : Colors.grey,
                              width: _selectedAssetImage == asset ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(asset, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload from Device'),
                  onPressed: _pickImage,
                ),
                const SizedBox(height: 8),
                if (_imageFile != null)
                  Image.file(_imageFile!, width: 80, height: 80, fit: BoxFit.cover)
                else if (_selectedAssetImage != null)
                  Image.asset(_selectedAssetImage!, width: 80, height: 80, fit: BoxFit.cover),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  onChanged: (val) => name = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => price = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter price' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (val) => category = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter category' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Size'),
                  onChanged: (val) => size = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter size' : null,
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _addProduct,
                    child: _loading ? CircularProgressIndicator() : Text('Add Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 