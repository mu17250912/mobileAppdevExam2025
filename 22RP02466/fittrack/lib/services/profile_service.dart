import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _key = 'user_profile';

  // Profile photo management
  static const String _profilePhotoKey = 'profile_photo_path';

  Future<void> saveProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<Profile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return null;
    return Profile.fromJson(jsonDecode(data));
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> saveProfilePhotoPath(String? photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (photoPath != null) {
      await prefs.setString(_profilePhotoKey, photoPath);
    } else {
      await prefs.remove(_profilePhotoKey);
    }
  }

  Future<String?> getProfilePhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePhotoKey);
  }

  Future<File?> getProfilePhoto() async {
    final photoPath = await getProfilePhotoPath();
    if (photoPath != null) {
      try {
        final file = File(photoPath);
        // Check if file exists without using existsSync() for web compatibility
        await file.length();
        return file;
      } catch (e) {
        // File doesn't exist or can't be accessed
        print('Profile photo not found: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> isUserPaid() async {
    final profile = await loadProfile();
    return profile?.isPaidUser ?? false;
  }
} 