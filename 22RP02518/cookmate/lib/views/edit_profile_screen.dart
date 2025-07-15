import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _emailAddressController;
  late String _role;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _emailAddressController = TextEditingController(text: widget.user.emailAddress ?? '');
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          if (_role == 'chef') ...{
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'emailAddress': _emailAddressController.text.trim(),
          },
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, AppUser(
          id: widget.user.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _role,
          phone: _role == 'chef' ? _phoneController.text.trim() : null,
          location: _role == 'chef' ? _locationController.text.trim() : null,
          emailAddress: _role == 'chef' ? _emailAddressController.text.trim() : null,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
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
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                items: AppUser.roles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role[0].toUpperCase() + role.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _role = value ?? 'user';
                  });
                },
                decoration: InputDecoration(labelText: 'Role'),
              ),
              if (_role == 'chef') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailAddressController,
                  decoration: InputDecoration(labelText: 'Contact Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter contact email' : null,
                ),
              ],
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 