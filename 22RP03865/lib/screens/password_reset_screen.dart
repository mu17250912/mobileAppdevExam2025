import 'package:flutter/material.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _email = value,
                  validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // TODO: Implement password reset logic
                    }
                  },
                  child: const Text('Send Reset Link'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to sign-in screen
                  },
                  child: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 