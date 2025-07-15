import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    nameController = TextEditingController(text: user?.name ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    locationController = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        location: locationController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Enter phone' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
