import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../services/voice_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  final VoiceService _voiceService = VoiceService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _emergencyService.getLocalContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading contacts: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Spouse, Doctor, Family',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  phoneController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relationship': relationshipController.text,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final contact = EmergencyContact(
          id: _emergencyService.generateContactId(),
          name: result['name']!,
          phoneNumber: result['phone']!,
          relationship: result['relationship'] ?? '',
        );

        await _emergencyService.addContact(contact);
        await _loadContacts();
        _showSuccessSnackBar('Contact added successfully');
      } catch (e) {
        _showErrorSnackBar('Error adding contact: $e');
      }
    }
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phoneNumber);
    final relationshipController = TextEditingController(text: contact.relationship);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Spouse, Doctor, Family',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  phoneController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relationship': relationshipController.text,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedContact = contact.copyWith(
          name: result['name']!,
          phoneNumber: result['phone']!,
          relationship: result['relationship'] ?? '',
        );

        await _emergencyService.updateContact(updatedContact);
        await _loadContacts();
        _showSuccessSnackBar('Contact updated successfully');
      } catch (e) {
        _showErrorSnackBar('Error updating contact: $e');
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _emergencyService.deleteContact(contact.id);
        await _loadContacts();
        _showSuccessSnackBar('Contact deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Error deleting contact: $e');
      }
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    try {
      // Speak the contact info for accessibility
      await _voiceService.speakEmergencyContact(contact.name, contact.relationship);
      
      // Call the contact
      await _emergencyService.callContact(contact);
    } catch (e) {
      _showErrorSnackBar('Error calling contact: $e');
    }
  }

  Future<void> _setPrimaryContact(EmergencyContact contact) async {
    try {
      await _emergencyService.setPrimaryContact(contact.id);
      await _loadContacts();
      _showSuccessSnackBar('${contact.name} set as primary contact');
    } catch (e) {
      _showErrorSnackBar('Error setting primary contact: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            tooltip: 'Add Emergency Contact',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Emergency Contacts',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add emergency contacts to quickly call for help',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Contact'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: contact.isPrimary 
                              ? Colors.red 
                              : Colors.blue,
                          child: Icon(
                            contact.isPrimary 
                                ? Icons.emergency 
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: TextStyle(
                            fontWeight: contact.isPrimary 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.phoneNumber),
                            if (contact.relationship.isNotEmpty)
                              Text(
                                contact.relationship,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            if (contact.isPrimary)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Primary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _callContact(contact),
                              icon: const Icon(Icons.call),
                              tooltip: 'Call ${contact.name}',
                              color: Colors.green,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editContact(contact);
                                    break;
                                  case 'primary':
                                    _setPrimaryContact(contact);
                                    break;
                                  case 'delete':
                                    _deleteContact(contact);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                if (!contact.isPrimary)
                                  const PopupMenuItem(
                                    value: 'primary',
                                    child: Row(
                                      children: [
                                        Icon(Icons.star),
                                        SizedBox(width: 8),
                                        Text('Set as Primary'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _contacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final primaryContact = await _emergencyService.getPrimaryContact();
                if (primaryContact != null) {
                  await _callContact(primaryContact);
                } else {
                  _showErrorSnackBar('No primary contact set');
                }
              },
              icon: const Icon(Icons.emergency),
              label: const Text('Call Primary'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
} 