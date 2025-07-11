import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoalService {
  final _goals = FirebaseFirestore.instance.collection('goals');
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[GoalService] No user signed in!');
      return '';
    }
    print('[GoalService] Current user UID: \'${user.uid}\'');
    return user.uid;
  }

  Stream<QuerySnapshot> getGoals() {
    try {
      final uid = _uid;
      if (uid.isEmpty) {
        print('[GoalService] getGoals: No UID, returning empty stream');
        return Stream.empty();
      }
      print('[GoalService] getGoals: Fetching goals for UID: $uid');
      return _goals.where('uid', isEqualTo: uid).snapshots();
    } catch (e) {
      print('[GoalService] getGoals error: $e');
      return Stream.empty();
    }
  }

  Future<void> addGoal(
    String title,
    String description, {
    DateTime? fromDate,
    DateTime? toDate,
    String status = 'in_progress',
  }) async {
    try {
      final uid = _uid;
      if (uid.isEmpty) {
        print('[GoalService] addGoal: No UID, cannot add goal');
        return;
      }
      print('[GoalService] addGoal: Adding goal for UID: $uid, title: $title');
      await _goals.add({
        'uid': uid,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
        'subgoals': [],
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      });
      // Send email after adding goal using EmailJS
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await sendGoalEmailWithEmailJS(
          userEmail: user.email!,
          subject: 'Goal Added',
          message:
              'You have added a new goal: $title\nDescription: $description',
        );
      }
    } catch (e) {
      print('[GoalService] addGoal error: $e');
    }
  }

  Future<void> updateGoal(
    String goalId, {
    String? title,
    String? description,
    String? status,
    List<Map<String, dynamic>>? subgoals,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (subgoals != null) data['subgoals'] = subgoals;
    await _goals.doc(goalId).update(data);
  }

  Future<void> deleteGoal(String goalId) async {
    // No platform block; allow on web and Windows
    await _goals.doc(goalId).delete();
  }

  // Remove old sendGoalEmail and sendGoalEmailViaCloudFunction methods
  // Add EmailJS method
  Future<void> sendGoalEmailWithEmailJS({
    required String userEmail,
    required String subject,
    required String message,
  }) async {
    const serviceId = 'service_w3m9mmr'; // Correct EmailJS service ID
    const templateId = 'template_3jkb5qj'; // Correct EmailJS template ID
    const userId = 'f5qXhqWBWSUjnU8cF'; // Provided EmailJS public key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'user_email': userEmail,
          'subject': subject,
          'message': message,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Email sent via EmailJS!');
    } else {
      print('Failed to send email via EmailJS: \\${response.body}');
    }
  }
}
