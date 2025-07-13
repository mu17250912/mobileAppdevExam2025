import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class DataExportService {
  final FirebaseService _firebaseService = FirebaseService();

  Future<String> exportUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Collect all user data
      final userData = await _collectUserData(user.uid);
      
      // Convert to JSON
      final jsonData = jsonEncode(userData);
      
      // Save to file
      final fileName = 'umutoni_novels_data_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await _saveToFile(fileName, jsonData);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    final userData = <String, dynamic>{};
    
    try {
      // User profile
      final userProfile = await _firebaseService.getUserProfile(userId);
      userData['profile'] = userProfile;
      
      // Favorites
      final favorites = await _firebaseService.getUserFavorites(userId);
      userData['favorites'] = favorites;
      
      // Notifications
      final notifications = await _firebaseService.getUserNotifications(userId);
      userData['notifications'] = notifications;
      
      // Orders
      final orders = await _firebaseService.getUserOrders(userId);
      userData['orders'] = orders;
      
      // Export metadata
      userData['exportMetadata'] = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'dataVersion': '1.0',
        'totalItems': {
          'favorites': favorites.length,
          'notifications': notifications.length,
          'orders': orders.length,
        }
      };
      
    } catch (e) {
      userData['error'] = 'Failed to collect some data: $e';
    }
    
    return userData;
  }

  Future<File> _saveToFile(String fileName, String content) async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory == null) {
      throw Exception('Could not access storage directory');
    }
    
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    
    return file;
  }

  Future<String> getExportPreview(String userId) async {
    try {
      final userData = await _collectUserData(userId);
      
      // Create a preview with limited data
      final preview = <String, dynamic>{
        'profile': userData['profile'] != null ? {
          'displayName': userData['profile']['displayName'],
          'email': userData['profile']['email'],
          'createdAt': userData['profile']['createdAt'],
        } : null,
        'summary': {
          'favoritesCount': userData['favorites']?.length ?? 0,
          'notificationsCount': userData['notifications']?.length ?? 0,
          'ordersCount': userData['orders']?.length ?? 0,
        },
        'exportDate': userData['exportMetadata']['exportDate'],
      };
      
      return jsonEncode(preview);
    } catch (e) {
      throw Exception('Failed to generate preview: $e');
    }
  }

  Future<void> shareExportedData(String filePath) async {
    // This would integrate with a sharing plugin
    // For now, we'll just return the file path
    print('Data exported to: $filePath');
  }
} 