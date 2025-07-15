import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditInternshipPage extends StatefulWidget {
  final String internshipId;
  const EditInternshipPage({Key? key, required this.internshipId}) : super(key: key);

  @override
  State<EditInternshipPage> createState() => _EditInternshipPageState();
}

class _EditInternshipPageState extends State<EditInternshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInternship();
  }

  Future<void> _loadInternship() async {
    final doc = await FirebaseFirestore.instance.collection('internships').doc(widget.internshipId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _locationController.text = data['location'] ?? '';
      _descriptionController.text = data['description'] ?? '';
    }
    setState(() { _loading = false; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await FirebaseFirestore.instance.collection('internships').doc(widget.internshipId).update({
      'title': _titleController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Internship updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              backgroundImage: AssetImage('assets/images/logo.png'),
              child: Icon(Icons.business_center, color: Color(0xFF0D3B24), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Internship',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D3B24),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 