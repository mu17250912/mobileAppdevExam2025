import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumUtils {
  static const int freeApplicationLimit = 5;

  // Returns true if the user has reached the free application limit
  static Future<bool> hasReachedApplicationLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final apps = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobseeker_id', isEqualTo: user.uid)
        .get();
    return apps.docs.length >= freeApplicationLimit && !(await isPremium());
  }

  // Returns true if the user is premium (stub, always false for now)
  static Future<bool> isPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    return data != null && data['isPremium'] == true;
  }

  // Show premium upgrade form dialog
  static Future<void> showPremiumUpgradeDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String paymentMethod = 'MTN Mobile Money';
    String plan = 'Monthly';
    final paymentController = TextEditingController();
    final nameController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium plan info
                Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Premium Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_view_month, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Monthly: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(' 20 USD'),
                            SizedBox(width: 24),
                            Icon(Icons.calendar_today, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Annual: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(' 199 USD'),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('• Unlimited job applications'),
                        Text('• Priority support'),
                        Text('• Featured profile for employers'),
                        Text('• Early access to new features'),
                        Text('• And more coming soon!'),
                      ],
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name on card / phone number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('Select Payment Method:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        items: const [
                          DropdownMenuItem(value: 'MTN Mobile Money', child: Text('MTN Mobile Money')),
                          DropdownMenuItem(value: 'Bank of Kigali', child: Text('Bank of Kigali')),
                          DropdownMenuItem(value: 'Paypal Card', child: Text('Paypal Card')),
                        ],
                        onChanged: (value) {
                          if (value != null) paymentMethod = value;
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: paymentController,
                        decoration: InputDecoration(
                          labelText: paymentMethod == 'MTN Mobile Money'
                              ? 'Mobile Number'
                              : paymentMethod == 'Bank of Kigali'
                                  ? 'Bank Account Number'
                                  : 'Paypal Email/Card',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('Select Plan:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: plan,
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                        ],
                        onChanged: (value) {
                          if (value != null) plan = value;
                        },
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('premium_control').add({
                  'user_id': user.uid,
                  'email': user.email,
                  'name_on_card': nameController.text.trim(),
                  'payment_method': paymentMethod,
                  'payment_details': paymentController.text.trim(),
                  'plan': plan,
                  'requested_at': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium upgrade request submitted! Wait for confirmation.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
} 