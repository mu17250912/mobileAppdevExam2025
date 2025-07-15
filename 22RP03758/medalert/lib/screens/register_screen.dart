import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for step 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controllers for step 2
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _roles = ['patient', 'caregiver'];
  String? _selectedRole;

  Map<String, dynamic>? _locationsJson;

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  String? _selectedCell;
  String? _selectedVillage;

  List<String> _districts = [];
  List<String> _sectors = [];
  List<String> _cells = [];
  List<String> _villages = [];

  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadLocationsJson();
  }

  Future<void> _loadLocationsJson() async {
    final jsonStr = await rootBundle.loadString('assets/rwanda_locations.json');
    setState(() {
      _locationsJson = json.decode(jsonStr);
    });
  }

  void _onProvinceChanged(String? province) {
    if (province == null) return;
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _selectedSector = null;
      _selectedCell = null;
      _selectedVillage = null;

      _districts = (_locationsJson?[province] as Map<String, dynamic>?)?.keys.toList() ?? [];
      _sectors = [];
      _cells = [];
      _villages = [];
    });
  }

  void _onDistrictChanged(String? district) {
    if (district == null || _selectedProvince == null) return;
    setState(() {
      _selectedDistrict = district;
      _selectedSector = null;
      _selectedCell = null;
      _selectedVillage = null;

      _sectors = (_locationsJson?[_selectedProvince]?[district] as Map<String, dynamic>?)?.keys.toList() ?? [];
      _cells = [];
      _villages = [];
    });
  }

  void _onSectorChanged(String? sector) {
    if (sector == null || _selectedProvince == null || _selectedDistrict == null) return;
    setState(() {
      _selectedSector = sector;
      _selectedCell = null;
      _selectedVillage = null;

      _cells = (_locationsJson?[_selectedProvince]?[_selectedDistrict]?[sector] as Map<String, dynamic>?)?.keys.toList() ?? [];
      _villages = [];
    });
  }

  void _onCellChanged(String? cell) {
    if (cell == null || _selectedProvince == null || _selectedDistrict == null || _selectedSector == null) return;
    setState(() {
      _selectedCell = cell;
      _selectedVillage = null;

      _villages = List<String>.from(_locationsJson?[_selectedProvince]?[_selectedDistrict]?[_selectedSector]?[cell] ?? []);
    });
  }

  void _onVillageChanged(String? village) {
    setState(() {
      _selectedVillage = village;
    });
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final pattern = r'^\+2507(8|9|2|3)\d{7}$';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return 'Enter a valid Rwandan phone number';
    }
    return null;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1 fields only
      if (_formKey.currentState!.validate()) {
        if (_selectedRole == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please select a role"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() => _currentStep = 1);
      }
    }
  }

  void _backStep() {
    setState(() => _currentStep = 0);
  }

  Future<void> _submit() async {
    // Validate all fields including step 2 dropdowns and passwords
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedSector == null ||
        _selectedCell == null ||
        _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select all location fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-not-created');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'sector': _selectedSector,
        'cell': _selectedCell,
        'village': _selectedVillage,
        'assignedCaregiverId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration successful! Please log in."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String message = "Registration failed";
      if (e.code == 'email-already-in-use') {
        message = "This email is already in use.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentStep >= 0 ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentStep >= 1 ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinces = _locationsJson?.keys.toList() ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _locationsJson == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading registration form...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App Logo/Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                size: 48,
                                color: Colors.blue,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Title
                            const Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            const Text(
                              'Join MedAlert to manage your health',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Step Indicator
                            _buildStepIndicator(),
                            
                            // Step Content
                            _currentStep == 0 ? _buildStep1() : _buildStep2(provinces),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            hintText: "Enter your full name",
            prefixIcon: const Icon(Icons.person, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (v) => v == null || v.isEmpty ? "Please enter your name" : null,
        ),

        const SizedBox(height: 20),

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email Address",
            hintText: "Enter your email address",
            prefixIcon: const Icon(Icons.email, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return "Please enter your email";
            final emailRegex = RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
                r"[a-zA-Z0-9]+\.[a-zA-Z]+");
            if (!emailRegex.hasMatch(v)) return "Enter a valid email";
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Phone Number",
            hintText: "Enter your phone number",
            prefixIcon: const Icon(Icons.phone, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: _validatePhone,
        ),

        const SizedBox(height: 20),

        // Role Dropdown
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Role",
            prefixIcon: const Icon(Icons.work, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          value: _selectedRole,
          items: _roles
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role[0].toUpperCase() + role.substring(1)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
          validator: (value) => value == null ? "Please select a role" : null,
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            "Next",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(List<String> provinces) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "Enter your password",
              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Please enter password";
              if (v.length < 6) return "Password must be at least 6 chars";
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              hintText: "Confirm your password",
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Please confirm password";
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Province Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Province",
              prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            value: _selectedProvince,
            items: provinces
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: _onProvinceChanged,
            validator: (v) => v == null ? "Please select a province" : null,
          ),

          const SizedBox(height: 20),

          // District Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "District",
              prefixIcon: const Icon(Icons.location_city, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            value: _selectedDistrict,
            items: _districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: _onDistrictChanged,
            validator: (v) => v == null ? "Please select a district" : null,
          ),

          const SizedBox(height: 20),

          // Sector Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Sector",
              prefixIcon: const Icon(Icons.business, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            value: _selectedSector,
            items: _sectors
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: _onSectorChanged,
            validator: (v) => v == null ? "Please select a sector" : null,
          ),

          const SizedBox(height: 20),

          // Cell Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Cell",
              prefixIcon: const Icon(Icons.home, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            value: _selectedCell,
            items: _cells
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: _onCellChanged,
            validator: (v) => v == null ? "Please select a cell" : null,
          ),

          const SizedBox(height: 20),

          // Village Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Village",
              prefixIcon: const Icon(Icons.home_work, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            value: _selectedVillage,
            items: _villages
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: _onVillageChanged,
            validator: (v) => v == null ? "Please select a village" : null,
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _backStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
