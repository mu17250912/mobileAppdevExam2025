import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saferide/firebase_options.dart';
import 'package:saferide/services/auth_service.dart';
import 'package:saferide/models/user_model.dart';

/// One-time migration to convert string date fields to Firestore Timestamps in rides collection
Future<void> migrateRideDateFieldsToTimestamps() async {
  final firestore = FirebaseFirestore.instance;
  final ridesRef = firestore.collection('rides');
  final rides = await ridesRef.get();
  int updated = 0;

  for (final doc in rides.docs) {
    final data = doc.data();
    bool needsUpdate = false;
    final updates = <String, dynamic>{};

    // Helper to convert string to Timestamp
    Timestamp? toTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is DateTime) return Timestamp.fromDate(value);
      if (value is String) {
        try {
          return Timestamp.fromDate(DateTime.parse(value));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    // List of date fields to check
    final dateFields = [
      'createdAt',
      'updatedAt',
      'departureTime',
      'lastActive'
    ];
    for (final field in dateFields) {
      final value = data[field];
      if (value != null && value is String) {
        final ts = toTimestamp(value);
        if (ts != null) {
          updates[field] = ts;
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate) {
      await doc.reference.update(updates);
      updated++;
    }
  }

  print('Migration complete. Updated $updated ride documents.');
}
