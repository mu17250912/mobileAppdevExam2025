import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'theme/app_colors.dart';
import 'subscription_screen.dart';
import 'subscription_benefits_screen.dart';
import 'user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;
  Map<String, dynamic>? _userData;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
        _nameController.text = _userData?['displayName'] ?? _user!.displayName ?? '';
      });
    } else {
      setState(() {
        _nameController.text = _user!.displayName ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() { _loading = true; });
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'displayName': _nameController.text.trim(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    } catch (e) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture and Basic Info
            Center(
              child: Column(
                children: [
                  if (_user!.photoURL != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_user!.photoURL!),
                    )
                  else
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _user!.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getSubscriptionColor(userProvider.subscriptionPlan),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${userProvider.subscriptionPlan ?? 'Basic'} Plan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Wide screen - horizontal layout
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildActionButtons(),
                        );
                      } else {
                        // Narrow screen - vertical layout
                        return Column(
                          children: _buildActionButtons().map((button) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                width: double.infinity,
                                child: button,
                              ),
                            )
                          ).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Profile Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _user!.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _loading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Update Profile'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: _user!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No orders yet.'),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('Order #${data['id']?.toString().substring(data['id'].toString().length - 8) ?? ''}'),
                        subtitle: Text('Total: RWF ${data['totalAmount']} | Status: ${data['status']}'),
                        trailing: Icon(
                          _getStatusIcon(data['status']),
                          color: _getStatusColor(data['status']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      ElevatedButton.icon(
        icon: const Icon(Icons.card_membership),
        label: const Text('Subscription'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionScreen(),
            ),
          );
        },
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.info),
        label: const Text('Benefits'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionBenefitsScreen(),
            ),
          );
        },
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: _logout,
      ),
    ];
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSubscriptionColor(String? plan) {
    switch (plan) {
      case 'Premium':
        return Colors.green;
      case 'Enterprise':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 