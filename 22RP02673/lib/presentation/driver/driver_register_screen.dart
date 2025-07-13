import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRegisterScreen extends StatefulWidget {
  static const String routeName = '/driver_register';
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _licenseController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _vehicleTypes = ['Sedan', 'SUV', 'Hatchback', 'Van', 'Other'];
  String _selectedVehicleType = 'Sedan';
  final _seatsController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _licenseController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _seatsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;
    // Check for required fields
    if (_nameController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _licenseController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty ||
        _carPlateController.text.trim().isEmpty ||
        _seatsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'role': 'driver',
        'driverInfo': {
          'license': _licenseController.text.trim(),
          'carModel': _carModelController.text.trim(),
          'carPlate': _carPlateController.text.trim(),
          'vehicleType': _selectedVehicleType,
          'seats': _seatsController.text.trim(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'available': true,
      }, SetOptions(merge: true));
    }
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/driver_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage('assets/driver_placeholder.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Phone or Email',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your phone or email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your license number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carModelController,
                decoration: const InputDecoration(
                  labelText: 'Car Model',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your car model' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carPlateController,
                decoration: const InputDecoration(
                  labelText: 'Car Plate Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your car plate number' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                items: _vehicleTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVehicleType = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.directions_bus),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Seats',
                  prefixIcon: Icon(Icons.event_seat),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter number of seats' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Number',
                  prefixIcon: Icon(Icons.chat),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter your WhatsApp number' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register as Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 