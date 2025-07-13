import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String category = '';
  String location = '';
  String budget = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post New Job'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) => setState(() => title = value),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title cannot be empty' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => setState(() => description = value),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Description cannot be empty' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (value) => setState(() => category = value),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Category cannot be empty' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (value) => setState(() => location = value),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Location cannot be empty' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Budget'),
                onChanged: (value) => setState(() => budget = value),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Budget cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _postJob,
                child: const Text('Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _postJob() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'budget': budget,
        'status': 'Open',
        'postedBy': user.uid,
        'applicants': [],
        'savedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posted!')));
    }
  }
} 