import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineData {
  final String id;
  final String type; // 'medication', 'medication_log', 'emergency_contact'
  final Map<String, dynamic> data;
  final String action; // 'create', 'update', 'delete'
  final DateTime timestamp;

  OfflineData({
    required this.id,
    required this.type,
    required this.data,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OfflineData.fromMap(Map<String, dynamic> map) {
    return OfflineData(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      data: map['data'] ?? {},
      action: map['action'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _offlineDataKey = 'offline_data';
  static const String _localDataKey = 'local_data';

  // Check if device is connected to internet
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }

  // Save data locally
  Future<void> saveLocalData(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_localDataKey}_${collection}_$documentId';
      
      // Convert Timestamps to ISO strings for JSON serialization
      final serializableData = _convertTimestampsToIso(data);
      
      await prefs.setString(key, jsonEncode(serializableData));
      debugPrint('Saved local data: $collection/$documentId');
    } catch (e) {
      debugPrint('Error saving local data: $e');
    }
  }

  // Convert Firestore Timestamps to ISO strings for JSON serialization
  Map<String, dynamic> _convertTimestampsToIso(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        converted[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.value is Map<String, dynamic>) {
        converted[entry.key] = _convertTimestampsToIso(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        converted[entry.key] = (entry.value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _convertTimestampsToIso(item);
          }
          return item;
        }).toList();
      } else {
        converted[entry.key] = entry.value;
      }
    }
    
    return converted;
  }

  // Get data from local storage
  Future<Map<String, dynamic>?> getLocalData(String collection, String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_localDataKey}_${collection}_$documentId';
      final dataString = prefs.getString(key);
      if (dataString != null) {
        return jsonDecode(dataString);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local data: $e');
      return null;
    }
  }

  // Get all local data for a collection
  Future<List<Map<String, dynamic>>> getAllLocalData(String collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final collectionKeys = keys.where((key) => key.startsWith('${_localDataKey}_${collection}_'));
      
      final data = <Map<String, dynamic>>[];
      for (final key in collectionKeys) {
        final dataString = prefs.getString(key);
        if (dataString != null) {
          data.add(jsonDecode(dataString));
        }
      }
      
      return data;
    } catch (e) {
      debugPrint('Error getting all local data: $e');
      return [];
    }
  }

  // Add offline operation to queue
  Future<void> addOfflineOperation(OfflineData offlineData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataList = await getOfflineOperations();
      offlineDataList.add(offlineData);
      
      final offlineDataJson = offlineDataList
          .map((data) => jsonEncode(data.toMap()))
          .toList();
      
      await prefs.setStringList(_offlineDataKey, offlineDataJson);
      debugPrint('Added offline operation: ${offlineData.type}/${offlineData.action}');
    } catch (e) {
      debugPrint('Error adding offline operation: $e');
    }
  }

  // Get all offline operations
  Future<List<OfflineData>> getOfflineOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getStringList(_offlineDataKey) ?? [];
      
      return offlineDataJson
          .map((json) => OfflineData.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error getting offline operations: $e');
      return [];
    }
  }

  // Clear offline operations
  Future<void> clearOfflineOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineDataKey);
      debugPrint('Cleared offline operations');
    } catch (e) {
      debugPrint('Error clearing offline operations: $e');
    }
  }

  // Sync offline operations with Firestore
  Future<void> syncOfflineOperations() async {
    try {
      if (!await isConnected()) {
        debugPrint('No internet connection, skipping sync');
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user, skipping sync');
        return;
      }

      final offlineOperations = await getOfflineOperations();
      if (offlineOperations.isEmpty) {
        debugPrint('No offline operations to sync');
        return;
      }

      debugPrint('Syncing ${offlineOperations.length} offline operations');

      for (final operation in offlineOperations) {
        try {
          switch (operation.type) {
            case 'medication':
              await _syncMedicationOperation(operation);
              break;
            case 'medication_log':
              await _syncMedicationLogOperation(operation);
              break;
            case 'emergency_contact':
              await _syncEmergencyContactOperation(operation);
              break;
            default:
              debugPrint('Unknown operation type: ${operation.type}');
          }
        } catch (e) {
          debugPrint('Error syncing operation ${operation.id}: $e');
        }
      }

      // Clear offline operations after successful sync
      await clearOfflineOperations();
      debugPrint('Offline operations synced successfully');
    } catch (e) {
      debugPrint('Error syncing offline operations: $e');
    }
  }

  // Sync medication operation
  Future<void> _syncMedicationOperation(OfflineData operation) async {
    final user = _auth.currentUser;
    if (user == null) return;

    switch (operation.action) {
      case 'create':
      case 'update':
        await _firestore
            .collection('medications')
            .doc(operation.id)
            .set({
          ...operation.data,
          'patientId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'delete':
        await _firestore
            .collection('medications')
            .doc(operation.id)
            .delete();
        break;
    }
  }

  // Sync medication log operation
  Future<void> _syncMedicationLogOperation(OfflineData operation) async {
    final user = _auth.currentUser;
    if (user == null) return;

    switch (operation.action) {
      case 'create':
        await _firestore
            .collection('medication_logs')
            .add({
          ...operation.data,
          'patientId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'update':
        await _firestore
            .collection('medication_logs')
            .doc(operation.id)
            .update({
          ...operation.data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'delete':
        await _firestore
            .collection('medication_logs')
            .doc(operation.id)
            .delete();
        break;
    }
  }

  // Sync emergency contact operation
  Future<void> _syncEmergencyContactOperation(OfflineData operation) async {
    final user = _auth.currentUser;
    if (user == null) return;

    switch (operation.action) {
      case 'create':
      case 'update':
        await _firestore
            .collection('emergency_contacts')
            .doc(operation.id)
            .set({
          ...operation.data,
          'patientId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'delete':
        await _firestore
            .collection('emergency_contacts')
            .doc(operation.id)
            .delete();
        break;
    }
  }

  // Download data from Firestore for offline use
  Future<void> downloadDataForOffline() async {
    try {
      if (!await isConnected()) {
        debugPrint('No internet connection, cannot download data');
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user, cannot download data');
        return;
      }

      debugPrint('Downloading data for offline use');

      // Download medications
      final medicationsSnapshot = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: user.uid)
          .get();

      for (final doc in medicationsSnapshot.docs) {
        await saveLocalData('medications', doc.id, doc.data());
      }

      // Download medication logs (simplified query to avoid index issues)
      final logsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: user.uid)
          .limit(100) // Limit to recent logs
          .get();

      for (final doc in logsSnapshot.docs) {
        await saveLocalData('medication_logs', doc.id, doc.data());
      }

      // Download emergency contacts
      final contactsSnapshot = await _firestore
          .collection('emergency_contacts')
          .where('patientId', isEqualTo: user.uid)
          .get();

      for (final doc in contactsSnapshot.docs) {
        await saveLocalData('emergency_contacts', doc.id, doc.data());
      }

      debugPrint('Data downloaded successfully for offline use');
    } catch (e) {
      debugPrint('Error downloading data for offline use: $e');
    }
  }

  // Get offline data with fallback to local storage
  Future<List<Map<String, dynamic>>> getOfflineData(String collection) async {
    try {
      if (await isConnected()) {
        // Try to get from Firestore first
        final user = _auth.currentUser;
        if (user != null) {
          final snapshot = await _firestore
              .collection(collection)
              .where('patientId', isEqualTo: user.uid)
              .get();
          
          // Save to local storage for offline use
          for (final doc in snapshot.docs) {
            await saveLocalData(collection, doc.id, doc.data());
          }
          
          return snapshot.docs.map((doc) => doc.data()).toList();
        }
      }
      
      // Fallback to local storage
      return await getAllLocalData(collection);
    } catch (e) {
      debugPrint('Error getting offline data: $e');
      // Fallback to local storage
      return await getAllLocalData(collection);
    }
  }

  // Initialize offline service
  Future<void> initialize() async {
    try {
      // Download data for offline use
      await downloadDataForOffline();
      
      // Listen to connectivity changes
      connectivityStream.listen((ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          // Internet connection restored, sync offline operations
          syncOfflineOperations();
        }
      });
      
      debugPrint('Offline service initialized');
    } catch (e) {
      debugPrint('Error initializing offline service: $e');
    }
  }
} 