import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _storageKey = 'emergency_contacts';

  // Get emergency contacts from local storage
  Future<List<EmergencyContact>> getLocalContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList(_storageKey) ?? [];
      
      return contactsJson
          .map((json) => EmergencyContact.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading local emergency contacts: $e');
      return [];
    }
  }

  // Save emergency contacts to local storage
  Future<void> saveLocalContacts(List<EmergencyContact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = contacts
          .map((contact) => jsonEncode(contact.toMap()))
          .toList();
      
      await prefs.setStringList(_storageKey, contactsJson);
    } catch (e) {
      debugPrint('Error saving local emergency contacts: $e');
    }
  }

  // Get emergency contacts from Firestore
  Future<List<EmergencyContact>> getFirestoreContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('emergency_contacts')
          .where('patientId', isEqualTo: user.uid)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading Firestore emergency contacts: $e');
      return [];
    }
  }

  // Save emergency contact to Firestore
  Future<void> saveFirestoreContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('emergency_contacts')
          .doc(contact.id)
          .set({
        'patientId': user.uid,
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'relationship': contact.relationship,
        'isPrimary': contact.isPrimary,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving Firestore emergency contact: $e');
    }
  }

  // Delete emergency contact from Firestore
  Future<void> deleteFirestoreContact(String contactId) async {
    try {
      await _firestore
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting Firestore emergency contact: $e');
    }
  }

  // Sync contacts between local storage and Firestore
  Future<void> syncContacts() async {
    try {
      final localContacts = await getLocalContacts();
      final firestoreContacts = await getFirestoreContacts();

      // Update local storage with Firestore data
      await saveLocalContacts(firestoreContacts);

      // Upload local contacts to Firestore if they don't exist
      for (final localContact in localContacts) {
        final exists = firestoreContacts.any((fc) => fc.id == localContact.id);
        if (!exists) {
          await saveFirestoreContact(localContact);
        }
      }
    } catch (e) {
      debugPrint('Error syncing emergency contacts: $e');
    }
  }

  // Add new emergency contact
  Future<void> addContact(EmergencyContact contact) async {
    try {
      // Add to local storage
      final localContacts = await getLocalContacts();
      localContacts.add(contact);
      await saveLocalContacts(localContacts);

      // Add to Firestore
      await saveFirestoreContact(contact);
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
    }
  }

  // Update existing emergency contact
  Future<void> updateContact(EmergencyContact contact) async {
    try {
      // Update local storage
      final localContacts = await getLocalContacts();
      final index = localContacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        localContacts[index] = contact;
        await saveLocalContacts(localContacts);
      }

      // Update Firestore
      await saveFirestoreContact(contact);
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
    }
  }

  // Delete emergency contact
  Future<void> deleteContact(String contactId) async {
    try {
      // Remove from local storage
      final localContacts = await getLocalContacts();
      localContacts.removeWhere((c) => c.id == contactId);
      await saveLocalContacts(localContacts);

      // Remove from Firestore
      await deleteFirestoreContact(contactId);
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
    }
  }

  // Call emergency contact
  Future<void> callContact(EmergencyContact contact) async {
    try {
      final phoneNumber = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = 'tel:$phoneNumber';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error calling emergency contact: $e');
      rethrow;
    }
  }

  // Get primary emergency contact
  Future<EmergencyContact?> getPrimaryContact() async {
    try {
      final contacts = await getLocalContacts();
      return contacts.firstWhere((contact) => contact.isPrimary);
    } catch (e) {
      // No primary contact found
      return null;
    }
  }

  // Set primary emergency contact
  Future<void> setPrimaryContact(String contactId) async {
    try {
      final contacts = await getLocalContacts();
      
      // Remove primary flag from all contacts
      for (int i = 0; i < contacts.length; i++) {
        contacts[i] = contacts[i].copyWith(isPrimary: false);
      }
      
      // Set the specified contact as primary
      final index = contacts.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        contacts[index] = contacts[index].copyWith(isPrimary: true);
      }
      
      // Save updated contacts
      await saveLocalContacts(contacts);
      
      // Update Firestore
      for (final contact in contacts) {
        await saveFirestoreContact(contact);
      }
    } catch (e) {
      debugPrint('Error setting primary emergency contact: $e');
    }
  }

  // Generate unique ID for new contact
  String generateContactId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
} 