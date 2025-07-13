import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfileManagementScreen extends StatefulWidget {
  const DriverProfileManagementScreen({super.key});

  @override
  State<DriverProfileManagementScreen> createState() => _DriverProfileManagementScreenState();
}

class _DriverProfileManagementScreenState extends State<DriverProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _nameController.text = data?['name'] ?? '';
        _contactController.text = data?['contact'] ?? '';
        _whatsappController.text = data?['whatsapp'] ?? '';
        _carModelController.text = data?['driverInfo']?['carModel'] ?? '';
        _carPlateController.text = data?['driverInfo']?['carPlate'] ?? '';
        _licenseController.text = data?['driverInfo']?['license'] ?? '';
        _vehicleTypeController.text = data?['driverInfo']?['vehicleType'] ?? '';
        _seatsController.text = data?['driverInfo']?['seats'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'driverInfo.carModel': _carModelController.text.trim(),
        'driverInfo.carPlate': _carPlateController.text.trim(),
        'driverInfo.license': _licenseController.text.trim(),
        'driverInfo.vehicleType': _vehicleTypeController.text.trim(),
        'driverInfo.seats': _seatsController.text.trim(),
      });
    }
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your contact' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(labelText: 'WhatsApp Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.chat)),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your WhatsApp number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carModelController,
                      decoration: const InputDecoration(labelText: 'Car Model', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your car model' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carPlateController,
                      decoration: const InputDecoration(labelText: 'Car Plate', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(labelText: 'License', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleTypeController,
                      decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatsController,
                      decoration: const InputDecoration(labelText: 'Seats', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 