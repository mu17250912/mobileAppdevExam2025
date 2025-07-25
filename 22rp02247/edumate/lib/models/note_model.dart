import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    // Helper function to parse DateTime from different formats
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      
      if (value is DateTime) {
        return value;
      }
      
      if (value is Timestamp) {
        return value.toDate();
      }
      
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing DateTime from string: $value');
          return DateTime.now();
        }
      }
      
      print('Unknown DateTime format: $value (${value.runtimeType})');
      return DateTime.now();
    }
    
    return NoteModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
} 