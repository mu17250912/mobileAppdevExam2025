import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  String? _type;
  String? _location;
  String? _role;
  bool _isPremiumBuyer = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      setState(() {
        _type = doc.data()?['type'] ?? 'abcd';
        _location = doc.data()?['location'] ?? 'xxx';
        _role = doc.data()?['role'] ?? 'customer';
        _isPremiumBuyer = doc.data()?['isPremiumBuyer'] == true;
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showEditProfile() {
    if (_role != 'admin') return;
    final typeController = TextEditingController(text: _type ?? 'abcd');
    final locationController = TextEditingController(text: _location ?? 'xxx');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newType = typeController.text.trim();
              final newLocation = locationController.text.trim();
              if (_user != null) {
                await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
                  'type': newType,
                  'location': newLocation,
                });
                setState(() {
                  _type = newType;
                  _location = newLocation;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Visa ending in 1234'),
              subtitle: const Text('Expires 12/25'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.green),
              title: const Text('Bank Account'),
              subtitle: const Text('****5678'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new payment method...')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings() {
    String selectedLanguage = 'English';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Language Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
              RadioListTile<String>(
                title: const Text('Kinyarwanda'),
                value: 'Kinyarwanda',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
              RadioListTile<String>(
                title: const Text('French'),
                value: 'French',
                groupValue: selectedLanguage,
                onChanged: (value) => setState(() => selectedLanguage = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $selectedLanguage')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Premium'),
        content: SizedBox(
          width: 350,
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unlock exclusive deals, priority support, and bulk order discounts!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premium Price: 2,000 FRW',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose your payment method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildPaymentOption(
                      icon: Icons.phone_android,
                      title: 'MTN Mobile Money',
                      subtitle: 'Pay via MTN Mobile Money',
                      color: Colors.yellow.shade700,
                      onTap: () => _processBuyerPayment('MTN Mobile Money'),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Pay with Visa, Mastercard, etc.',
                      color: Colors.blue.shade600,
                      onTap: () => _processBuyerPayment('Credit/Debit Card'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _processBuyerPayment(String paymentMethod) async {
    Navigator.pop(context); // Close the payment method selection dialog
    // Simulate payment dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Processing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing $paymentMethod payment...'),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your payment.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    // Set isPremiumBuyer in Firestore
    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'isPremiumBuyer': true});
      setState(() {
        _isPremiumBuyer = true;
      });
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful via $paymentMethod! You are now a Premium Buyer!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C7B7B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Image.asset(
              'assets/images/logo1.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 8),
            const Text(
              'T-Find',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8800),
              ),
            ),
            const SizedBox(height: 24),
            // User Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user?.displayName ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Show type and location only for admin
                      if (_role == 'admin')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_type ?? 'abcd'),
                            const SizedBox(width: 16),
                            Text('Location: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_location ?? 'xxx'),
                          ],
                        ),
                      // Show 'Premium Member' badge only if premium
                      if (_isPremiumBuyer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Premium Member',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isPremiumBuyer) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _showGoPremiumDialog,
                  icon: const Icon(Icons.star, color: Colors.amber),
                  label: const Text('Go Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Profile actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.person, size: 36, color: Colors.blue),
                      title: const Text('Edit Profile Information'),
                      subtitle: const Text('Update your personal details'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _role == 'admin' ? _showEditProfile : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.payment, size: 36, color: Colors.green),
                      title: const Text('Payment Methods'),
                      subtitle: const Text('Manage your payment options'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showPaymentMethods,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.language, size: 36, color: Colors.orange),
                      title: const Text('Language Settings'),
                      subtitle: const Text('Choose your preferred language'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showLanguageSettings,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.help, size: 36, color: Colors.purple),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Get help and contact support'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening help center...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
} 