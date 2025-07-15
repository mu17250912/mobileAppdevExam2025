import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'emergency_contacts_screen.dart';

Future<void> launchStripeCheckout() async {
  final Uri url = Uri.parse('https://buy.stripe.com/test_xxx...'); // Your real Stripe payment link
  if (!await canLaunchUrl(url)) {
    throw 'Could not launch $url';
  }
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

class ReportAlertScreen extends StatefulWidget {
  const ReportAlertScreen({Key? key}) : super(key: key);

  @override
  State<ReportAlertScreen> createState() => _ReportAlertScreenState();
}

class _ReportAlertScreenState extends State<ReportAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  String _alertType = 'Crime';
  String _description = '';
  String _location = '';
  XFile? _pickedImage;
  bool _isSubmitting = false;

  final List<String> _alertTypes = [
    'Crime', 'Accident', 'Fire', 'Suspicious Activity', 'Other'
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<String?> _uploadImage(String alertId) async {
    if (_pickedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child('alert_images/$alertId.jpg');
    await ref.putData(await _pickedImage!.readAsBytes());
    return await ref.getDownloadURL();
  }

  Future<void> _submitAlert() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      setState(() { _isSubmitting = true; });
      final alertRef = await FirebaseFirestore.instance.collection('alerts').add({
        'type': _alertType,
        'description': _description,
        'location': _location,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid, // null if not signed in
        'status': 'pending',
      });
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await _uploadImage(alertRef.id);
        await alertRef.update({'photoUrl': photoUrl});
      }
      setState(() { _isSubmitting = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert reported successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Alert')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Remove the always-visible form, only show the FAB for adding alerts
            const SizedBox(height: 32),
            Text('All Submitted Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No alerts found.'));
                }
                final alerts = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final data = alerts[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.warning, color: Colors.redAccent),
                        title: Text(data['type'] ?? 'Alert'),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: data['timestamp'] != null
                            ? Text(
                                _formatTimeAgo(data['timestamp']),
                                style: TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Submit Alert'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _alertType,
                items: _alertTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _alertType = value);
                },
                decoration: const InputDecoration(labelText: 'Alert Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: (value) => _description = value,
                validator: (value) => value != null && value.isNotEmpty ? null : 'Enter a description',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location (auto/manual)'),
                onChanged: (value) => _location = value,
                validator: (value) => value != null && value.isNotEmpty ? null : 'Enter a location',
              ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
              ),
              ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                      final user = FirebaseAuth.instance.currentUser;
                      setState(() { _isSubmitting = true; });
                      final alertRef = await FirebaseFirestore.instance.collection('alerts').add({
                        'type': _alertType,
                        'description': _description,
                        'location': _location,
                        'timestamp': FieldValue.serverTimestamp(),
                        'userId': user?.uid, // null if not signed in
                        'status': 'pending',
                      });
                      setState(() { _isSubmitting = false; });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert reported successfully!')),
                      );
                  }
                },
                  child: _isSubmitting ? CircularProgressIndicator() : Text('Submit Alert'),
              ),
            ],
          ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Alert',
      ),
    );
  }
}

String _formatTimeAgo(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${date.month}/${date.day}/${date.year}';
} 