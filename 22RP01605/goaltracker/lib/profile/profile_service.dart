import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class ProfileService {
  final _users = FirebaseFirestore.instance.collection('users');

  String get _uid {
    // No platform block; allow on web and Windows
    return FirebaseAuth.instance.currentUser!.uid;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final doc = await _users.doc(_uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<String> _generateUniqueReferralCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    String code;
    bool exists = true;
    do {
      code = List.generate(
        5,
        (index) => chars[rand.nextInt(chars.length)],
      ).join();
      final query = await _users
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<void> createProfile({
    required String email,
    String? username,
    String? telephone,
    String? referrer,
  }) async {
    try {
      print('[ProfileService] Creating profile for $email');
      final referralCode = await _generateUniqueReferralCode();
      await _users.doc(_uid).set({
        'email': email,
        'username': username ?? '',
        'telephone': telephone ?? '',
        'xp': 0,
        'trackedGoals': [],
        'premium': false,
        'referralCode': referralCode,
        'referrer': referrer ?? '',
        'referralCount': 0,
      });
      if (referrer != null && referrer.isNotEmpty) {
        await updateReferralCountAndPremium(referrer);
      }
      print('[ProfileService] Profile created for $email');
    } catch (e) {
      print('[ProfileService] createProfile error: $e');
    }
  }

  Future<void> upgradeToPremium() async {
    await _users.doc(_uid).update({'premium': true});
  }

  Future<void> updateProfile({
    String? email,
    String? username,
    String? telephone,
    int? xp,
    List<String>? trackedGoals,
    Future<bool> Function(String)? reauthCallback,
  }) async {
    final data = <String, dynamic>{};
    if (email != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != email) {
          try {
            await user.verifyBeforeUpdateEmail(email);
            print('[ProfileService] Verification email sent to $email');
            if (reauthCallback != null) {
              await reauthCallback(
                'A verification email has been sent to $email. Please check your inbox and verify to complete the update.',
              );
            }
            return; // Do not update Firestore until verified
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login' && reauthCallback != null) {
              print('[ProfileService] Email update requires re-authentication');
              final success = await reauthCallback(email);
              if (!success) {
                print(
                  '[ProfileService] Email update aborted after failed re-auth',
                );
                return;
              }
            } else if (e.message != null &&
                e.message!.toLowerCase().contains('verify the new email')) {
              print(
                '[ProfileService] Email update blocked: verification required',
              );
              if (reauthCallback != null) {
                await reauthCallback(
                  'Please verify your new email address using the link sent to your inbox before changing your email again.',
                );
              }
              return;
            } else {
              print('[ProfileService] Error updating FirebaseAuth email: $e');
              if (reauthCallback != null) {
                await reauthCallback(
                  'Error updating email: ${e.message ?? e.toString()}',
                );
              }
              return;
            }
          }
        }
        data['email'] = email;
      } catch (e) {
        print('[ProfileService] Error updating FirebaseAuth email: $e');
        return;
      }
    }
    if (username != null) data['username'] = username;
    if (telephone != null) data['telephone'] = telephone;
    if (xp != null) data['xp'] = xp;
    if (trackedGoals != null) data['trackedGoals'] = trackedGoals;
    try {
      print('[ProfileService] Updating profile for $_uid with $data');
      await _users.doc(_uid).update(data);
      print('[ProfileService] Profile updated for $_uid');
    } catch (e) {
      print('[ProfileService] updateProfile error: $e');
    }
  }

  Future<void> updateReferralCountAndPremium(String referralCode) async {
    // Find all users who have this referralCode as their referrer
    final query = await _users.where('referrer', isEqualTo: referralCode).get();
    final count = query.docs.length;
    // Update the user's referralCount
    final userDoc = await _users
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final docRef = userDoc.docs.first.reference;
      await docRef.update({'referralCount': count});
      if (count > 4) {
        await docRef.update({'premium': true});
      }
    }
  }

  Future<String?> uploadProfileImage(
    String uid,
    dynamic imageData, {
    bool isWeb = false,
  }) async {
    try {
      print(
        '[ProfileService] uploadProfileImage called for uid=$uid, isWeb=$isWeb',
      );
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );
      if (kIsWeb && isWeb) {
        print('[ProfileService] Attempting putData for web');
        await ref.putData(imageData as Uint8List);
      } else {
        print('[ProfileService] Attempting putFile for mobile/desktop');
        await ref.putFile(File((imageData as XFile).path));
      }
      final url = await ref.getDownloadURL();
      print('[ProfileService] Got download URL: $url');
      return url;
    } catch (e) {
      print('[ProfileService] uploadProfileImage error: $e');
      return null;
    }
  }
}
