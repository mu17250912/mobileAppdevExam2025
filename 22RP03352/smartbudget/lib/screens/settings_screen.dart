import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../main.dart'; // For highContrastMode
import 'payment_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DocumentSnapshot? _userDoc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: _loadUserData called. User: ${user?.uid}');
    
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        print('DEBUG: Firestore document fetched: ${doc.exists}');
        if (doc.exists) {
          final data = doc.data();
          print('DEBUG: Firestore data: $data');
          print('DEBUG: photoUrl from Firestore: ${data?['photoUrl']}');
        }
        
        print('DEBUG: Firebase Auth photoURL: ${user.photoURL}');
        
        setState(() {
          _userDoc = doc;
        });
        print('DEBUG: State updated with new user document');
      } catch (e) {
        print('DEBUG: Error loading user data: $e');
      }
    } else {
      print('DEBUG: No user found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green[800],
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          // Profile Section
          Center(
            child: _userDoc == null
                ? CircularProgressIndicator()
                : Builder(
                    builder: (context) {
                      final firestoreData = _userDoc!.data() as Map<String, dynamic>?;
                      final displayName = user?.displayName ?? firestoreData?['displayName'] ?? '';
                      final photoUrl = user?.photoURL ?? firestoreData?['photoUrl'];
                      
                      print('DEBUG: UI - displayName: $displayName');
                      print('DEBUG: UI - photoUrl: $photoUrl');
                      print('DEBUG: UI - user.photoURL: ${user?.photoURL}');
                      print('DEBUG: UI - firestoreData photoUrl: ${firestoreData?['photoUrl']}');
                      
                      return Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.green[100],
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null ? Icon(Icons.person, size: 48, color: Colors.green[800]) : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isLoading ? null : () async {
                                    try {
                                      setState(() => _isLoading = true);
                                      print('DEBUG: Starting image picker...');
                                      
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                                      
                                      if (picked == null) {
                                        print('DEBUG: No image selected');
                                        return;
                                      }
                                      
                                      print('DEBUG: Image selected: ${picked.name}');
                                      
                                      if (user == null) {
                                        print('DEBUG: User is null');
                                        return;
                                      }
                                      
                                      print('DEBUG: User ID: ${user.uid}');
                                      
                                      final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
                                      print('DEBUG: Storage reference created: ${ref.fullPath}');
                                      
                                      if (kIsWeb) {
                                        print('DEBUG: Running on web platform');
                                        // Web: use putData
                                        final bytes = await picked.readAsBytes();
                                        print('DEBUG: Image bytes loaded: ${bytes.length} bytes');
                                        
                                        final uploadTask = await ref.putData(bytes);
                                        print('DEBUG: Upload task completed. State: ${uploadTask.state}');
                                        
                                        if (uploadTask.state == TaskState.success) {
                                          final url = await ref.getDownloadURL();
                                          print('DEBUG: Download URL obtained: $url');
                                          
                                          await user.updatePhotoURL(url);
                                          print('DEBUG: Firebase Auth photoURL updated');
                                          
                                          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoUrl': url});
                                          print('DEBUG: Firestore photoUrl updated');
                                          
                                          await _loadUserData(); // Refresh data
                                          print('DEBUG: User data refreshed');
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Profile image updated!')),
                                          );
                                        } else {
                                          print('DEBUG: Upload failed. State: ${uploadTask.state}');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Image upload failed. Please try again.')),
                                          );
                                        }
                                      } else {
                                        print('DEBUG: Running on mobile/desktop platform');
                                        // Mobile/desktop: use putFile
                                        final file = File(picked.path);
                                        print('DEBUG: File created: ${file.path}');
                                        
                                        final uploadTask = await ref.putFile(file);
                                        print('DEBUG: Upload task completed. State: ${uploadTask.state}');
                                        
                                        if (uploadTask.state == TaskState.success) {
                                          final url = await ref.getDownloadURL();
                                          print('DEBUG: Download URL obtained: $url');
                                          
                                          await user.updatePhotoURL(url);
                                          print('DEBUG: Firebase Auth photoURL updated');
                                          
                                          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoUrl': url});
                                          print('DEBUG: Firestore photoUrl updated');
                                          
                                          await _loadUserData(); // Refresh data
                                          print('DEBUG: User data refreshed');
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Profile image updated!')),
                                          );
                                        } else {
                                          print('DEBUG: Upload failed. State: ${uploadTask.state}');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Image upload failed. Please try again.')),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      print('DEBUG: Error occurred: $e');
                                      print('DEBUG: Error stack trace: ${StackTrace.current}');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: \n${e.toString()}')),
                                      );
                                    } finally {
                                      setState(() => _isLoading = false);
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: _isLoading 
                                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Icon(Icons.camera_alt, size: 16, color: Colors.green[800]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName.isNotEmpty ? displayName : (user?.email ?? 'No email'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'User Profile',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: Icon(Icons.edit, size: 18),
                            label: Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final displayNameController = TextEditingController(text: displayName);
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Edit Profile'),
                                    content: TextField(
                                      controller: displayNameController,
                                      decoration: InputDecoration(labelText: 'Display Name'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newName = displayNameController.text.trim();
                                          if (newName.isNotEmpty && user != null) {
                                            await user.updateDisplayName(newName);
                                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'displayName': newName});
                                            Navigator.of(context).pop();
                                            await _loadUserData(); // Refresh data
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Profile updated!')),
                                            );
                                          }
                                        },
                                        child: Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 32),
          // Account Section
          const Text(
            'Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.green),
                  title: const Text('Change Password'),
                  onTap: () async {
                    if (user?.email != null) {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No email found for this user.')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Payment Section
          const Text(
            'Payment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.green),
                  title: const Text('Payment History'),
                  subtitle: const Text('View your transaction history'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // App Section (future expansion)
          const Text(
            'App',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.green),
                  title: const Text('About BudgetWise'),
                  subtitle: const Text('Version 1.0.1'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'BudgetWise',
                      applicationVersion: '1.0.1',
                      applicationLegalese: '© 2024 BudgetWise Team',
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.contrast, color: Colors.amber[800]),
                  title: Text('High Contrast Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: ValueListenableBuilder<bool>(
                    valueListenable: highContrastMode,
                    builder: (context, isHighContrast, _) {
                      return Switch(
                        value: isHighContrast,
                        onChanged: (val) => highContrastMode.value = val,
                        activeColor: Colors.amber[800],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 