import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class Task {
  final String? docId; // Firestore document ID
  final int? id; // For legacy/local use
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final TimeOfDay time;
  final bool isCompleted;
  final bool reminder;

  Task({
    this.docId,
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.reminder = false,
  });

  Task copyWith({
    String? docId,
    int? id,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    TimeOfDay? time,
    bool? isCompleted,
    bool? reminder,
  }) {
    return Task(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      reminder: reminder ?? this.reminder,
    );
  }

  // Add toMap/fromMap for SQLite
} 