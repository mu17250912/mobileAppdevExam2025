import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../models/notification_item.dart'; // <-- Use this import

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = []; // <-- Start empty

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n.unread).length;

  void markAllRead() {
    for (var n in _notifications) {
      n.unread = false;
    }
    notifyListeners();
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int index) {
    if (_notifications[index].unread) {
      _notifications[index].unread = false;
      notifyListeners();
    }
  }
}
