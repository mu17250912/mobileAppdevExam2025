import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../seller/seller_dashboard.dart';
import '../buyer/buyer_main_screen.dart';
import '../../models/user.dart'; // For UserRole
import '../../main.dart'; // Import for AuthGate

class CompleteProfileScreen extends StatefulWidget {
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController phoneController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    phoneController = TextEditingController(text: user?.phone ?? '');
    locationController = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        phone: phoneController.text.trim(),
        location: locationController.text.trim(),
      );
      final user = authProvider.user;
      if (user != null) {
        if (user.role == UserRole.farmer) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => SellerDashboard()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => BuyerMainScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: kPrimaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Please complete your profile to continue.', style: TextStyle(fontSize: 18)),
              SizedBox(height: 24),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Enter phone number' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
