import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('emergency_contacts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No emergency contacts found.'));
          }
          final contacts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final doc = contacts[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(_getIcon(data['type']), color: Colors.redAccent),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text('Phone: \\${data['phone'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        onPressed: () async {
                          final phone = data['phone'];
                          if (phone != null && phone.toString().isNotEmpty) {
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          _showAddOrEditDialog(context, doc.id, data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('emergency_contacts').doc(doc.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(context, null, null),
        child: const Icon(Icons.add),
        tooltip: 'Add Emergency Contact',
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.local_fire_department;
      case 'ambulance':
        return Icons.local_hospital;
      case 'disaster':
        return Icons.warning;
      default:
        return Icons.phone;
    }
  }

  void _showAddOrEditDialog(BuildContext context, String? docId, Map<String, dynamic>? data) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final phoneController = TextEditingController(text: data?['phone'] ?? '');
    String type = data?['type'] ?? 'police';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Emergency Contact' : 'Edit Emergency Contact'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'police', child: Text('Police')),
                  DropdownMenuItem(value: 'fire', child: Text('Fire Service')),
                  DropdownMenuItem(value: 'ambulance', child: Text('Ambulance')),
                  DropdownMenuItem(value: 'disaster', child: Text('Disaster Management')),
                ],
                onChanged: (v) => type = v ?? 'police',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final contactData = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'type': type,
                };
                if (docId == null) {
                  await FirebaseFirestore.instance.collection('emergency_contacts').add(contactData);
                } else {
                  await FirebaseFirestore.instance.collection('emergency_contacts').doc(docId).update(contactData);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 