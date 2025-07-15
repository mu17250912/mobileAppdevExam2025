import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'property_model.dart';
import 'theme.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _propertyType = 'rent';
  String _category = 'house';
  final List<String> _amenities = [
    'Parking',
    'Balcony',
    'Garden',
    'Security',
    'Swimming Pool',
    'Gym',
    'Internet',
  ];
  final Set<String> _selectedAmenities = {};
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  int _bedrooms = 0;
  int _bathrooms = 0;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBytes = result.files.single.bytes;
        _selectedImageName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadToCloudinary(
    Uint8List imageBytes,
    String fileName,
  ) async {
    const cloudName = 'dwavfe9yo';
    const uploadPreset = 'easyrent_unsigned';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'] as String?;
    } else {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      String imageUrl = '';
      if (_selectedImageBytes != null && _selectedImageName != null) {
        final uploaded = await _uploadToCloudinary(
          _selectedImageBytes!,
          _selectedImageName!,
        );
        if (uploaded == null) throw Exception('Image upload failed');
        imageUrl = uploaded;
      }
      final property = Property(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        status: 'available',
        imageUrl: imageUrl,
        ownerId: user.uid,
        category: _category,
        amenities: _selectedAmenities.toList(),
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        propertyType: _propertyType, // <-- add this
      );
      await FirebaseFirestore.instance
          .collection('properties')
          .add(property.toMap());
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add property: \\${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: const TextStyle(
        color: kPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Property',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: inputDecoration.copyWith(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descController,
                decoration: inputDecoration.copyWith(labelText: 'Description'),
                minLines: 2,
                maxLines: 5,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _priceController,
                decoration: inputDecoration.copyWith(labelText: 'Price (RWF)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _propertyType,
                decoration: inputDecoration.copyWith(
                  labelText: 'Property Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'rent', child: Text('Rent')),
                  DropdownMenuItem(value: 'sale', child: Text('Sale')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _propertyType = v);
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: inputDecoration.copyWith(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'house', child: Text('House')),
                  DropdownMenuItem(
                    value: 'apartment',
                    child: Text('Apartment'),
                  ),
                  DropdownMenuItem(value: 'villa', child: Text('Villa')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select category' : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: inputDecoration.copyWith(
                        labelText: 'Bedrooms',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter bedrooms';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Invalid number';
                        return null;
                      },
                      onSaved: (v) => _bedrooms = int.tryParse(v ?? '') ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: inputDecoration.copyWith(
                        labelText: 'Bathrooms',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter bathrooms';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Invalid number';
                        return null;
                      },
                      onSaved: (v) => _bathrooms = int.tryParse(v ?? '') ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Amenities',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _amenities.map((amenity) {
                  final selected = _selectedAmenities.contains(amenity);
                  return ChoiceChip(
                    label: Text(amenity),
                    selected: selected,
                    selectedColor: kPrimaryColor.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selected ? kPrimaryColor : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? kPrimaryColor : Colors.grey.shade400,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _addressController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Address/Location',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text('Upload Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: _pickImage,
                    ),
              if (_selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        child: const Text('Add Property'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
