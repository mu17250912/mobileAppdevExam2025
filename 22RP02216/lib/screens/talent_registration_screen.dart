import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';

class TalentRegistrationScreen extends StatefulWidget {
  const TalentRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<TalentRegistrationScreen> createState() =>
      _TalentRegistrationScreenState();
}

class _TalentRegistrationScreenState extends State<TalentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _talentTypeController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _moreInfoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  File? _pickedImage;
  Uint8List? _pickedImageBytes; // For web
  String? _photoUrl;

  final List<String> _talentTypes = [
    'DJ',
    'MC',
    'Dancer',
    'Singer',
    'Comedian',
    'Magician',
    'Band',
    'Speaker',
    'Photographer',
    'Videographer',
    'Other',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        _pickedImageBytes = bytes;
        await _uploadImageToCloudinaryWeb(bytes);
      }
    } else {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        _pickedImage = File(picked.path);
        await _uploadImageToCloudinary(_pickedImage!);
      }
    }
  }

  Future<void> _uploadImageToCloudinaryWeb(Uint8List bytes) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dwavfe9yo/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'easyrent_unsigned'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'),
      );
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final urlMatch = RegExp(r'"secure_url":"(.*?)"').firstMatch(respStr);
      if (urlMatch != null) {
        final imageUrl = urlMatch.group(1)?.replaceAll(r'\/', '/');
        _photoUrl = imageUrl;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadImageToCloudinary(File image) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dwavfe9yo/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'easyrent_unsigned'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final urlMatch = RegExp(r'"secure_url":"(.*?)"').firstMatch(respStr);
      if (urlMatch != null) {
        final imageUrl = urlMatch.group(1)?.replaceAll(r'\/', '/');
        _photoUrl = imageUrl;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _registerTalent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'role': 'talent',
            'name': _nameController.text.trim(),
            'talentType': _talentTypeController.text.trim(),
            'contact': _contactController.text.trim(),
            'price': _priceController.text.trim(),
            'email': _emailController.text.trim(),
            'photoUrl': _photoUrl ?? '',
            'moreInfo': _moreInfoController.text.trim(),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Talent Registration',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: size.width * 0.85,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Remove avatar and label from the top of the form
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownSearch<String>(
                    items: _talentTypes,
                    selectedItem: _talentTypeController.text.isNotEmpty
                        ? _talentTypeController.text
                        : null,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search or add talent type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      menuProps: MenuProps(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(title: Text(item));
                      },
                      emptyBuilder: (context, searchEntry) {
                        return ListTile(
                          title: Text('Add "$searchEntry"'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _talentTypeController.text = searchEntry;
                          },
                        );
                      },
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Talent Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Select or enter talent type'
                        : null,
                    onChanged: (value) {
                      _talentTypeController.text = value ?? '';
                    },
                    onSaved: (value) {
                      _talentTypeController.text = value ?? '';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact Info',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your contact info'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Service Price (RWF)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your price'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  // More Information Section
                  Card(
                    color: Colors.deepPurple.withOpacity(0.04),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.deepPurple.withOpacity(0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More Information',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _moreInfoController,
                            maxLines: 5,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Describe your experience, skills, portfolio, or anything that makes you stand out...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.withOpacity(0.15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Upload Profile Image Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload, color: Colors.deepPurple),
                      label: const Text(
                        'Upload Profile Image',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_pickedImage != null ||
                      (_photoUrl != null && _photoUrl!.isNotEmpty) ||
                      _pickedImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: kIsWeb
                                  ? (_pickedImageBytes != null
                                        ? Image.memory(
                                            _pickedImageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : (_photoUrl != null &&
                                              _photoUrl!.isNotEmpty)
                                        ? Image.network(
                                            _photoUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : null)
                                  : _pickedImage != null
                                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  ? Image.network(_photoUrl!, fit: BoxFit.cover)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Profile image selected',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 6,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _registerTalent();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Register',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
