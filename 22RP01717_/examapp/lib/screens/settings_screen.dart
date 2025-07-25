import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:exam_app/screens/premium_screen.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  final String? email;
  final bool isPremium;
  final VoidCallback? onResetProgress;
  final bool isDarkMode;
  final ValueChanged<bool>? onDarkModeChanged;
  final String? displayName;
  final String? avatarUrl;
  final String? uid;

  const SettingsScreen({
    this.email,
    this.isPremium = false,
    this.onResetProgress,
    this.isDarkMode = false,
    this.onDarkModeChanged,
    this.displayName,
    this.avatarUrl,
    this.uid,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetting = false;
  bool _saving = false;
  String? _displayName;
  String? _avatarUrl;
  File? _avatarFile;
  Uint8List? _avatarWebBytes;
  int _testLength = 10;
  bool _showExplanations = true;
  String _difficulty = 'Any';
  bool _downloadingQuestions = false;
  bool _downloaded = false;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName ?? '';
    _avatarUrl = widget.avatarUrl;
    _loadCustomSettings();
  }

  Future<void> _loadCustomSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _testLength = prefs.getInt('testLength') ?? 10;
      _showExplanations = prefs.getBool('showExplanations') ?? true;
      _difficulty = prefs.getString('difficulty') ?? 'Any';
    });
  }

  Future<void> _saveCustomSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('testLength', _testLength);
    await prefs.setBool('showExplanations', _showExplanations);
    await prefs.setString('difficulty', _difficulty);
  }

  Future<void> _resetProgress() async {
    setState(() { _resetting = true; });
    await ProgressService().saveProgress({});
    await ProgressService().saveMockTestScore('dummy', 0); // Clear mock test scores
    setState(() { _resetting = false; });
    if (widget.onResetProgress != null) widget.onResetProgress!();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Progress reset!')));
  }

  Future<void> _pickAvatar() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _avatarWebBytes = result.files.single.bytes;
          _avatarFile = null;
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
          _avatarWebBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    final ref = FirebaseStorage.instance.ref().child('avatars/${widget.uid ?? 'user'}.jpg');
    if (kIsWeb && _avatarWebBytes != null) {
      await ref.putData(_avatarWebBytes!);
      return await ref.getDownloadURL();
    } else if (_avatarFile != null) {
      await ref.putFile(_avatarFile!);
      return await ref.getDownloadURL();
    }
    return _avatarUrl;
  }

  Future<void> _saveProfile() async {
    print('Starting _saveProfile');
    setState(() { _saving = true; });
    String? avatarUrl = _avatarUrl;
    print('Current avatarUrl: ' + (avatarUrl ?? 'null'));
    print('UID: ' + (widget.uid ?? 'null'));
    if ((kIsWeb && _avatarWebBytes != null) || (!kIsWeb && _avatarFile != null)) {
      print('Uploading avatar...');
      avatarUrl = await _uploadAvatar();
      print('Avatar uploaded. New URL: ' + (avatarUrl ?? 'null'));
    }
    print('Updating Firestore user profile...');
    await FirestoreService().updateUserProfile(
      widget.uid ?? '',
      displayName: _displayName,
      avatarUrl: avatarUrl,
    );
    print('Firestore user profile updated.');
    // Fetch updated user and update provider
    if (widget.uid != null && widget.uid!.isNotEmpty) {
      print('Fetching updated user from Firestore...');
      final updatedUserDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (updatedUserDoc.exists) {
        print('Updated user found. Updating provider...');
        final updatedUser = UserModel.fromMap(updatedUserDoc.data()!);
        Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);
      } else {
        print('Updated user not found in Firestore.');
      }
    } else {
      print('UID is null or empty, skipping provider update.');
    }
    setState(() {
      _avatarUrl = avatarUrl;
      _saving = false;
    });
    print('Profile save complete.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated!')));
  }

  Future<void> _downloadAllQuestions() async {
    setState(() {
      _downloadingQuestions = true;
      _downloadStatus = 'Downloading...';
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('questions').get();
      final questions = snapshot.docs.map((doc) => doc.data()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_questions_all', jsonEncode(questions));
      setState(() {
        _downloaded = true;
        _downloadStatus = 'Downloaded ${questions.length} questions.';
      });
    } catch (e) {
      setState(() {
        _downloadStatus = 'Download failed.';
      });
    } finally {
      setState(() {
        _downloadingQuestions = false;
      });
    }
  }

  Future<void> _clearOfflineQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_questions_all');
    setState(() {
      _downloaded = false;
      _downloadStatus = 'Offline questions cleared.';
    });
  }

  Future<void> _exportOfflineQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('offline_questions_all');
      if (data == null) {
        setState(() { _downloadStatus = 'No offline questions to export.'; });
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offline_questions.json');
      await file.writeAsString(data);
      setState(() { _downloadStatus = 'Exported to: ${file.path}'; });
    } catch (e) {
      setState(() { _downloadStatus = 'Export failed.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarProvider;
    if (kIsWeb && _avatarWebBytes != null) {
      avatarProvider = MemoryImage(_avatarWebBytes!);
    } else if (!kIsWeb && _avatarFile != null) {
      avatarProvider = FileImage(_avatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      avatarProvider = NetworkImage(_avatarUrl!);
    } else {
      avatarProvider = AssetImage('assets/avatar_placeholder.png');
    }
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.indigo),
                    title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(_displayName ?? '', style: GoogleFonts.poppins()),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _pickAvatar,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage: avatarProvider,
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.edit, size: 18, color: Colors.indigo),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                decoration: InputDecoration(labelText: 'Display Name'),
                                controller: TextEditingController(text: _displayName)
                                  ..selection = TextSelection.collapsed(offset: _displayName?.length ?? 0),
                                onChanged: (val) => setState(() => _displayName = val),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _saveProfile();
                              },
                              child: Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text('Dark Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) {
                      themeProvider.toggleDarkMode(val);
                    },
                    secondary: Icon(Icons.dark_mode, color: Colors.deepPurple),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customize Test Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.format_list_numbered, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Test Length: $_testLength questions', style: GoogleFonts.poppins()),
                                  Slider(
                                    value: _testLength.toDouble(),
                                    min: 5,
                                    max: 50,
                                    divisions: 9,
                                    label: '$_testLength',
                                    onChanged: (val) {
                                      setState(() {
                                        _testLength = val.round();
                                      });
                                      _saveCustomSettings();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: SwitchListTile(
                                title: Text('Show Explanations', style: GoogleFonts.poppins()),
                                value: _showExplanations,
                                onChanged: (val) {
                                  setState(() {
                                    _showExplanations = val;
                                  });
                                  _saveCustomSettings();
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.leaderboard, color: Colors.deepPurple),
                            SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _difficulty,
                                decoration: InputDecoration(labelText: 'Difficulty'),
                                items: ['Any', 'Easy', 'Medium', 'Hard']
                                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _difficulty = val ?? 'Any';
                                  });
                                  _saveCustomSettings();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offline Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.download, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _downloadingQuestions ? null : _downloadAllQuestions,
                                child: Text(_downloadingQuestions ? 'Downloading...' : 'Download All Questions'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _clearOfflineQuestions,
                                child: Text('Clear Offline Questions'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.save_alt, color: Colors.teal),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _exportOfflineQuestions,
                                child: Text('Export Offline Questions'),
                              ),
                            ),
                          ],
                        ),
                        if (_downloadStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_downloadStatus, style: GoogleFonts.poppins(fontSize: 13, color: Colors.deepPurple)),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Colors.orange),
                    title: Text('Reset Progress', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    onTap: _resetting ? null : _resetProgress,
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.workspace_premium, color: Colors.amber),
                    title: Text('Premium Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(widget.isPremium ? 'Premium User' : 'Normal User', style: GoogleFonts.poppins()),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Premium Status', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: widget.isPremium
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.amber, size: 48),
                                  SizedBox(height: 12),
                                  Text('You are a Premium User!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text('Thank you for supporting us!', style: GoogleFonts.poppins()),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.amber, size: 48),
                                  SizedBox(height: 12),
                                  Text('Upgrade to Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text('Unlock all categories, remove ads, and get exclusive features.', style: GoogleFonts.poppins()),
                                ],
                              ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                            if (!widget.isPremium)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumScreen()));
                                },
                                child: Text('Upgrade Now'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 