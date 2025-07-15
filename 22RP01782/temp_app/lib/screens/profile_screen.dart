import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  List<String> _skills = [];
  String? _profilePicUrl;
  File? _profilePicFile;
  String? _notifCategory;
  double? _notifMinPay;
  final List<String> _notifCategories = ['Any', 'Design', 'Writing', 'Tutoring', 'Delivery', 'Other'];

  bool _loading = true;
  String? _error;

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'User not logged in';
        _loading = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _skills = List<String>.from(data['skills'] ?? []);
          _profilePicUrl = data['profilePicUrl'];
          _notifCategory = data['notifCategory'] ?? 'Any';
          _notifMinPay = (data['notifMinPay'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      _error = 'Failed to load profile';
    }
    setState(() {
      _loading = false;
    });
  }

  void _refreshProfilePicture() {
    setState(() {
      // Force UI refresh for profile picture
    });
  }

  Future<void> _saveProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'User not logged in';
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Prepare profile data
      final profileData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': _skills,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Upload profile picture if changed
      bool hasNewPicture = (kIsWeb && _profilePicBytes != null) || 
                          (!kIsWeb && _profilePicFile != null && _profilePicFile!.path.isNotEmpty);
      
      if (hasNewPicture) {
        try {
          // Show upload progress
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Uploading profile picture...'),
                  ],
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          final profilePicUrl = await _uploadProfilePic(user.uid);
          if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
            profileData['profilePicUrl'] = profilePicUrl;
            // Update the local state immediately
            setState(() {
              _profilePicUrl = profilePicUrl;
            });
            // Force UI refresh
            _refreshProfilePicture();
          }
        } catch (e) {
          print('Profile picture upload failed: $e');
          if (mounted) {
            String errorMessage = 'Profile picture upload failed. ';
            if (e.toString().contains('timeout')) {
              errorMessage += 'Please try with a smaller image (under 300KB) or check your internet connection.';
            } else {
              errorMessage += 'Please try again with a smaller image (under 300KB).';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Skip Photo',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // Clear the profile picture data to skip upload
                    setState(() {
                      _profilePicBytes = null;
                      _profilePicFile = null;
                    });
                    // Show success message for profile save without photo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile saved without photo. You can add a photo later.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            );
          }
          // Continue without profile picture
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear the temporary profile picture data after successful save
        setState(() {
          _profilePicBytes = null;
          _profilePicFile = null;
        });
        
        // Reload profile to show updated data
        _loadProfile();
      }
    } catch (e) {
      print('Profile save error: $e');
      setState(() {
        _error = 'Failed to update profile: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickProfilePic() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          // Check file size (max 1MB for web to prevent timeouts)
          if (bytes.length > 1 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 1MB. Please choose a smaller image or compress it first.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          setState(() {
            _profilePicFile = File(''); // Placeholder for web
            _profilePicBytes = bytes;
          });
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery, 
          imageQuality: 30, // Further reduced quality for smaller file size
          maxWidth: 400.0, // Further reduced max width
          maxHeight: 400.0, // Further reduced max height
        );
        if (picked != null) {
          final file = File(picked.path);
          // Check file size (max 1MB for mobile to prevent timeouts)
          if (await file.length() > 1 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 1MB. Please choose a smaller image or compress it first.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          setState(() {
            _profilePicFile = file;
            _profilePicBytes = null;
          });
        }
      }
    } catch (e) {
      print('Error picking profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Uint8List? _profilePicBytes;

  Future<String?> _uploadProfilePic(String uid) async {
    try {
      if (kIsWeb && _profilePicBytes != null) {
        // For web, try with even smaller chunks and multiple retries
        return await _uploadWebImage(uid, _profilePicBytes!);
      } else if (_profilePicFile != null && _profilePicFile!.path.isNotEmpty) {
        // For mobile, try with compressed image and multiple retries
        return await _uploadMobileImage(uid, _profilePicFile!);
      }
      return _profilePicUrl;
    } catch (e) {
      print('Profile picture upload error: $e');
      rethrow;
    }
  }

  Future<String?> _uploadWebImage(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref().child('profile_pics').child('$uid.jpg');
    
    // Try multiple times with different approaches
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Web upload attempt $attempt...');
        
        final uploadTask = ref.putData(bytes);
        
        // Use shorter timeout for each attempt
        final timeoutDuration = Duration(seconds: 8 - (attempt - 1) * 2);
        
        await uploadTask.timeout(
          timeoutDuration,
          onTimeout: () {
            throw Exception('Upload timeout on attempt $attempt');
          },
        );
        
        print('Web upload successful on attempt $attempt');
        return await ref.getDownloadURL();
        
      } catch (e) {
        print('Web upload attempt $attempt failed: $e');
        if (attempt == 3) {
          throw Exception('Upload failed after 3 attempts. Please try with a smaller image (under 300KB) or check your internet connection.');
        }
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return null;
  }

  Future<String?> _uploadMobileImage(String uid, File file) async {
    final ref = FirebaseStorage.instance.ref().child('profile_pics').child('$uid.jpg');
    
    // Try with original file first, then progressively smaller versions
    List<File> filesToTry = [file];
    
    // Try to create smaller versions
    try {
      final smallerFile = await _createSmallerImage(file, 200.0, 200.0, 15);
      if (smallerFile != null) {
        filesToTry.add(smallerFile);
      }
      
      final tinyFile = await _createSmallerImage(file, 150.0, 150.0, 10);
      if (tinyFile != null) {
        filesToTry.add(tinyFile);
      }
    } catch (e) {
      print('Error creating smaller images: $e');
    }
    
    for (int fileIndex = 0; fileIndex < filesToTry.length; fileIndex++) {
      final currentFile = filesToTry[fileIndex];
      
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          print('Mobile upload attempt $attempt with file $fileIndex...');
          
          final uploadTask = ref.putFile(currentFile);
          
          final timeoutDuration = Duration(seconds: 6 - (attempt - 1) * 2);
          
          await uploadTask.timeout(
            timeoutDuration,
            onTimeout: () {
              throw Exception('Upload timeout on attempt $attempt');
            },
          );
          
          print('Mobile upload successful on attempt $attempt with file $fileIndex');
          return await ref.getDownloadURL();
          
        } catch (e) {
          print('Mobile upload attempt $attempt with file $fileIndex failed: $e');
          if (fileIndex == filesToTry.length - 1 && attempt == 2) {
            throw Exception('Upload failed after multiple attempts. Please try with a smaller image (under 200KB) or check your internet connection.');
          }
          // Wait a bit before retrying
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    return null;
  }

  Future<File?> _createSmallerImage(File originalFile, double? maxWidth, double? maxHeight, int quality) async {
    try {
      final picker = ImagePicker();
      final compressed = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      
      if (compressed != null) {
        final compressedFile = File(compressed.path);
        final fileSize = await compressedFile.length();
        
        // Check if the compressed file is small enough
        if (fileSize <= 200 * 1024) { // 200KB
          return compressedFile;
        }
      }
      return null;
    } catch (e) {
      print('Image compression failed: $e');
      return null;
    }
  }



  Future<void> _exportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Export Gigs
    final appsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('applications')
        .get();
    List<List<dynamic>> gigRows = [
      ['Job ID', 'Status', 'Amount', 'Completed At'],
    ];
    for (final doc in appsSnap.docs) {
      final data = doc.data();
      gigRows.add([
        data['jobId'] ?? '',
        data['status'] ?? '',
        data['amount'] ?? '',
        data['completedAt']?.toString() ?? '',
      ]);
    }
    // Export Income (from completed gigs)
    // (Already included above, so we can skip a separate income export)
    String csvData = const ListToCsvConverter().convert(gigRows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/gigs_export.csv');
    await file.writeAsString(csvData);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to ${file.path}')),
    );
  }

  Future<void> _saveNotificationPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'notifCategory': _notifCategory ?? 'Any',
      'notifMinPay': _notifMinPay ?? 0,
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved!')),
    );
  }

  Future<void> _buildResume() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Fetch completed gigs
    final appsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('applications')
        .where('status', isEqualTo: 'completed')
        .get();
    final gigs = appsSnap.docs.map((doc) => doc.data()).toList();
    // Build PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Resume')), 
          pw.Text('Name: ${_nameController.text}'),
          pw.Text('Phone: ${_phoneController.text}'),
          pw.Text('Bio: ${_bioController.text}'),
          pw.Text('Skills: ${_skills.join(', ')}'),
          pw.SizedBox(height: 16),
          pw.Text('Completed Gigs:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Bullet(
            text: gigs.isEmpty ? 'No completed gigs yet.' : ''
          ),
          ...gigs.map((gig) => pw.Bullet(
            text: 'Title: ${gig['jobId'] ?? ''} | Amount: ${gig['amount'] ?? ''} | Completed: ${gig['completedAt']?.toString() ?? ''}'
          )),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'resume.pdf');
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  ImageProvider<Object>? _getProfileImage() {
    if (kIsWeb && _profilePicBytes != null) {
      return MemoryImage(_profilePicBytes!);
    } else if (_profilePicFile != null && _profilePicFile!.path.isNotEmpty) {
      return FileImage(_profilePicFile!);
    } else if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
      return NetworkImage(_profilePicUrl!);
    }
    return null;
  }

  bool _shouldShowCameraIcon() {
    return (kIsWeb && _profilePicBytes == null || !kIsWeb && (_profilePicFile == null || _profilePicFile!.path.isEmpty)) && (_profilePicUrl == null || _profilePicUrl!.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return  Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(_error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfilePic,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                    backgroundImage: _getProfileImage(),
                    child: _shouldShowCameraIcon() 
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple)
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Full Name', labelStyle: Theme.of(context).textTheme.titleMedium),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number', labelStyle: Theme.of(context).textTheme.titleMedium),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter your phone' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(labelText: 'Bio', labelStyle: Theme.of(context).textTheme.titleMedium),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillController,
                        decoration: InputDecoration(labelText: 'Add Skill', labelStyle: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final skill = _skillController.text.trim();
                        if (skill.isNotEmpty && !_skills.contains(skill)) {
                          setState(() {
                            _skills.add(skill);
                            _skillController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: _skills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _skills.remove(skill);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Saving...'),
                            ],
                          )
                        : const Text('Save Profile'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data (CSV)'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/help'),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help & FAQ'),
                ),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                  builder: (context, snapshot) {
                    final isPremium = snapshot.data?.data()?['premium'] ?? false;
                    if (!isPremium) return const SizedBox.shrink();
                    return Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _buildResume,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Build Resume (PDF)'),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Custom Gig Notifications', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _notifCategory ?? 'Any',
                                  items: _notifCategories.map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _notifCategory = val),
                                  decoration: InputDecoration(labelText: 'Category', labelStyle: Theme.of(context).textTheme.titleMedium),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _notifMinPay?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'Minimum Pay ( 24)', labelStyle: Theme.of(context).textTheme.titleMedium),
                                  onChanged: (val) => _notifMinPay = double.tryParse(val),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _saveNotificationPrefs,
                                  child: const Text('Save Notification Preferences'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
