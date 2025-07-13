import 'package:flutter/material.dart';
import '../../../models/property.dart';
import 'package:provider/provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/auth_provider.dart';

class AddPropertyScreen extends StatefulWidget {
  final Property? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFootageController = TextEditingController();
  final _addressController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _amenitiesController = TextEditingController();
  PropertyType _selectedType = PropertyType.apartment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _titleController.text = widget.property!.title;
      _descriptionController.text = widget.property!.description;
      _rentController.text = widget.property!.monthlyRent.toString();
      _bedroomsController.text = widget.property!.bedrooms.toString();
      _bathroomsController.text = widget.property!.bathrooms.toString();
      _addressController.text = widget.property!.address;
      _imageUrlController.text = widget.property!.images.join(', ');
      _selectedType = widget.property!.propertyType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rentController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFootageController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final images = _imageUrlController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // DEBUG PRINTS
    print('Attempting to add property...');
    print('Current user:  [32m${authProvider.currentUser?.id} [0m');
    print('Images: $images');

    final property = Property(
      id: widget.property?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      landlordId: authProvider.currentUser?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      monthlyRent: double.tryParse(_rentController.text.trim()) ?? 0,
      propertyType: _selectedType,
      bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 1,
      bathrooms: int.tryParse(_bathroomsController.text.trim()) ?? 1,
      squareFootage: 0, // Not used
      address: _addressController.text.trim(),
      latitude: 0.0,
      longitude: 0.0,
      images: images,
      amenities: [], // Not used
      landlordName: '',
      landlordPhone: '',
      isAvailable: true,
      isFeatured: false,
      rating: 0.0,
      reviewCount: 0,
      createdAt: widget.property?.createdAt ?? DateTime.now(),
    );

    print('Property to add:  [34m${property.toJson()} [0m');

    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    if (widget.property == null) {
      await propertyProvider.addProperty(property);
    } else {
      await propertyProvider.updateProperty(property);
    }
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.property == null ? 'Property added successfully!' : 'Property updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(labelText: 'Monthly Rent'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter rent' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PropertyType>(
                value: _selectedType,
                items: PropertyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (type) {
                  setState(() => _selectedType = type!);
                },
                decoration: const InputDecoration(labelText: 'Property Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bedroomsController,
                decoration: const InputDecoration(labelText: 'Bedrooms'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter bedrooms' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bathroomsController,
                decoration: const InputDecoration(labelText: 'Bathrooms'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter bathrooms' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URLs (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter at least one image URL' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
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
} 