import 'package:flutter/material.dart';

class ActivityItem {
  final String type; // 'homework', 'attendance', 'message'
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.icon,
    required this.color,
  });
} 