import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class CleanerProfilePage extends StatefulWidget {
  @override
  State<CleanerProfilePage> createState() => _CleanerProfilePageState();
}

class _CleanerProfilePageState extends State<CleanerProfilePage> {
  void _showEditProfileDialog(Map<String, dynamic> data, User user) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name'] ?? user.displayName ?? '');
    final emailController = TextEditingController(text: data['email'] ?? user.email ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    bool loading = false;
    String? error;
    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'phone': phoneController.text.trim(),
                            });
                            await user.updateDisplayName(nameController.text.trim());
                            await user.updateEmail(emailController.text.trim());
                            if (mounted) Navigator.of(context).pop('updated');
                          } on FirebaseAuthException catch (e) {
                            setState(() => error = e.message);
                          } catch (e) {
                            setState(() => error = 'Failed to update profile.');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    if (result == 'updated') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  void _showChangePasswordDialog(User user) async {
    final _formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool loading = false;
    String? error;
    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (v) => v == null || v.isEmpty ? 'Enter your current password' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPasswordController.text.trim(),
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newPasswordController.text.trim());
                            if (mounted) Navigator.of(context).pop('changed');
                          } on FirebaseAuthException catch (e) {
                            setState(() => error = e.message);
                          } catch (e) {
                            setState(() => error = 'Failed to change password.');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();
    if (result == 'changed') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF6A8DFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found.'));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name'] ?? user.displayName ?? 'Cleaner';
                final email = data['email'] ?? user.email ?? '';
                final phone = data['phone'] ?? '';
                final createdAt = (data['createdAt'] != null && data['createdAt'] is Timestamp)
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                return Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFF6A8DFF),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (context.watch<UserProvider>().isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.star, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(email, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone, size: 18, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(phone, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              ],
                            ),
                          ],
                          if (createdAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Joined: \\${createdAt.day}/\\${createdAt.month}/\\${createdAt.year}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A8DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showEditProfileDialog(data, user),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.lock),
                            label: const Text('Change Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A8DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showChangePasswordDialog(user),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 