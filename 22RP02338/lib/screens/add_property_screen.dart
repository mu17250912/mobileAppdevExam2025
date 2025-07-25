import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<File> _images = [];
  final picker = ImagePicker();

  String _title = '';
  String _description = '';
  double _price = 0;
  String _propertyType = 'house';
  String _listingType = 'sale';
  int _bedrooms = 1;
  int _bathrooms = 1;
  double _area = 0;
  String _address = '';
  List<String> _amenities = [];

  final List<String> _allAmenities = [
    'Parking', 'Gym', 'Pool', 'Balcony', 'Garden', 'Garage', 'Fireplace', 'Concierge', 'Rooftop Pool'
  ];

  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final propertyProvider = context.read<PropertyProvider>();
    final user = authProvider.currentUser;

    // For demo, use local file paths as image URLs
    final imageUrls = _images.map((f) => f.path).toList();

    final property = Property(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title,
      description: _description,
      price: _price,
      propertyType: _propertyType,
      listingType: _listingType,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      area: _area,
      address: _address,
      latitude: 0,
      longitude: 0,
      images: imageUrls,
      amenities: _amenities,
      ownerId: user?.id ?? '',
      ownerName: user?.fullName ?? '',
      ownerPhone: user?.phone ?? '',
      ownerEmail: user?.email ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isFeatured: false,
      additionalDetails: {},
    );

    final success = await propertyProvider.addProperty(property);
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(propertyProvider.error ?? 'Failed to add property.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              _buildImagePicker(),
              const SizedBox(height: AppSizes.lg),
              // Title
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: AppSizes.md),
              // Description
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: AppSizes.md),
              // Price
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
                onSaved: (v) => _price = double.tryParse(v ?? '0') ?? 0,
              ),
              const SizedBox(height: AppSizes.md),
              // Property Type
              DropdownButtonFormField<String>(
                value: _propertyType,
                decoration: const InputDecoration(labelText: 'Property Type'),
                items: const [
                  DropdownMenuItem(value: 'house', child: Text('House')),
                  DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                  DropdownMenuItem(value: 'land', child: Text('Land')),
                  DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                ],
                onChanged: (v) => setState(() => _propertyType = v ?? 'house'),
              ),
              const SizedBox(height: AppSizes.md),
              // Listing Type
              DropdownButtonFormField<String>(
                value: _listingType,
                decoration: const InputDecoration(labelText: 'Listing Type'),
                items: const [
                  DropdownMenuItem(value: 'sale', child: Text('For Sale')),
                  DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                ],
                onChanged: (v) => setState(() => _listingType = v ?? 'sale'),
              ),
              const SizedBox(height: AppSizes.md),
              // Bedrooms
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bedrooms'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (v) => v == null || v.isEmpty ? 'Enter bedrooms' : null,
                onSaved: (v) => _bedrooms = int.tryParse(v ?? '1') ?? 1,
              ),
              const SizedBox(height: AppSizes.md),
              // Bathrooms
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bathrooms'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (v) => v == null || v.isEmpty ? 'Enter bathrooms' : null,
                onSaved: (v) => _bathrooms = int.tryParse(v ?? '1') ?? 1,
              ),
              const SizedBox(height: AppSizes.md),
              // Area
              TextFormField(
                decoration: const InputDecoration(labelText: 'Area (sq ft)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter area' : null,
                onSaved: (v) => _area = double.tryParse(v ?? '0') ?? 0,
              ),
              const SizedBox(height: AppSizes.md),
              // Address
              TextFormField(
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
                onSaved: (v) => _address = v ?? '',
              ),
              const SizedBox(height: AppSizes.md),
              // Amenities
              Text('Amenities', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: AppSizes.sm,
                children: _allAmenities.map((amenity) {
                  final selected = _amenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _amenities.add(amenity);
                        } else {
                          _amenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.lg),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                  ),
                );
              }
              final file = _images[index];
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      image: DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
} 