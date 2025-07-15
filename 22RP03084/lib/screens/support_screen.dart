import 'package:flutter/material.dart';
import '../../main.dart';
import 'app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = false;
  String? _success;

  void _send() async {
    setState(() { _loading = true; _success = null; });
    await Future.delayed(const Duration(seconds: 1)); // Simulate send
    setState(() {
      _loading = false;
      _success = 'Message sent! We will get back to you soon.';
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: kGoldenBrown,
      ),
      drawer: AppDrawer(userId: '', isEmployer: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.amber[50],
              margin: const EdgeInsets.only(bottom: 18),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Support Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 8),
                    Text('• Fill out the form below to contact our support team.'),
                    Text('• Please provide your name, email, and a detailed message.'),
                    Text('• We will respond to your inquiry as soon as possible.'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(labelText: 'Message'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      if (_loading) const CircularProgressIndicator(color: kGoldenBrown),
                      if (_success != null) ...[
                        Text(_success!, style: const TextStyle(color: Colors.green)),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _send,
                          style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
                          child: const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 