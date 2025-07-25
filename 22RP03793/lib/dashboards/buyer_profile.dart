import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final shippingAddressController = TextEditingController();
  final profilePictureController = TextEditingController();
  final newAddressController = TextEditingController();
  List<String> savedAddresses = [];
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    shippingAddressController.dispose();
    profilePictureController.dispose();
    newAddressController.dispose();
    super.dispose();
  }

  void loadProfile(Map<String, dynamic> data) {
    fullNameController.text = data['fullName'] ?? '';
    phoneController.text = data['phoneNumber'] ?? '';
    shippingAddressController.text = data['shippingAddress'] ?? '';
    profilePictureController.text = data['profilePictureUrl'] ?? '';
    savedAddresses = (data['savedAddresses'] as List?)?.cast<String>() ?? [];
    // Do NOT call setState here
  }

  Future<void> saveProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'shippingAddress': shippingAddressController.text.trim(),
        'profilePictureUrl': profilePictureController.text.trim(),
        'savedAddresses': savedAddresses,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeColor = Colors.blue[900]!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found.'));
                }
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  loadProfile(data);
                  final email = user.email ?? '';
                  final createdAt = data['createdAt'] != null && data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : null;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 420),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Profile Picture
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 54,
                                            backgroundColor: themeColor.withOpacity(0.08),
                                            child: CircleAvatar(
                                              radius: 48,
                                              backgroundImage: profilePictureController.text.isNotEmpty
                                                ? NetworkImage(profilePictureController.text)
                                                : null,
                                              child: profilePictureController.text.isEmpty
                                                ? Icon(Icons.account_circle, size: 80, color: themeColor)
                                                : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Section: Contact Info
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor)),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: fullNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: Icon(Icons.person),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          prefixIcon: Icon(Icons.phone),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (v) => v == null || v.isEmpty ? 'Enter your phone number' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: shippingAddressController,
                                        decoration: InputDecoration(
                                          labelText: 'Shipping Address',
                                          prefixIcon: Icon(Icons.location_on),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Enter your shipping address' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: profilePictureController,
                                        decoration: InputDecoration(
                                          labelText: 'Profile Picture URL',
                                          prefixIcon: Icon(Icons.image),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Section: Email (read-only)
                                      TextFormField(
                                        initialValue: email,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Section: Saved Addresses
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor)),
                                      ),
                                      ...savedAddresses.asMap().entries.map((entry) => Row(
                                        children: [
                                          Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 15))),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                savedAddresses.removeAt(entry.key);
                                              });
                                            },
                                          ),
                                        ],
                                      )),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: newAddressController,
                                              decoration: InputDecoration(
                                                labelText: 'Add Address',
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Colors.green),
                                            onPressed: () {
                                              final addr = newAddressController.text.trim();
                                              if (addr.isNotEmpty && !savedAddresses.contains(addr)) {
                                                setState(() {
                                                  savedAddresses.add(addr);
                                                  newAddressController.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Account Created
                                      if (createdAt != null)
                                        Text('Account Created: ${createdAt.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                      const SizedBox(height: 24),
                                      // Save Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          onPressed: () => saveProfile(user.uid),
                                          icon: const Icon(Icons.save),
                                          label: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Logout Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[700],
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          onPressed: () async {
                                            await FirebaseAuth.instance.signOut();
                                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                          },
                                          icon: const Icon(Icons.logout),
                                          label: const Text('Logout', style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Profile not found.'));
              },
            ),
    );
  }
} 