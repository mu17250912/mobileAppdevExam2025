import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Simulate a user profile (in a real app, this would come from a backend or provider)
  User user = User(name: 'John Doe', email: 'johndoe@email.com', phone: '+1234567890');
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _name = user.name;
    _email = user.email;
    _phone = user.phone;
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        user.name = _name;
        user.email = _email;
        user.phone = _phone;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isEditing
            ? Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (value) => _name = value,
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Enter your name',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (value) => _email = value,
                      validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      onChanged: (value) => _phone = value,
                      validator: (value) => value != null && value.length >= 8 ? null : 'Enter a valid phone',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text(user.phone, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Sign out
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
      ),
    );
  }
} 