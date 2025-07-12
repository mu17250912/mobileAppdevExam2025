import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscribePage extends StatelessWidget {
  const SubscribePage({Key? key}) : super(key: key);

  Future<void> _handleSubscribe(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isPremium': true});
    }
    await Provider.of<UserProvider>(context, listen: false).refreshUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription successful! Premium features unlocked.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe'),
        backgroundColor: const Color(0xFF6A8DFF),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Unlock premium features!\nApply for unlimited jobs and more.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Subscribe for Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _handleSubscribe(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 