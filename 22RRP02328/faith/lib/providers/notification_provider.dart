import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await NotificationService.getUserNotifications(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await NotificationService.getAllNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 