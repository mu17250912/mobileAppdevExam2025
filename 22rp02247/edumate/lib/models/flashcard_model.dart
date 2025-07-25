import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardModel {
  final String id;
  final String userId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStudied;
  final int studyCount;
  final DateTime? lastStudiedAt;
  final String? noteId; // Reference to source note if generated from note

  FlashcardModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
    this.isStudied = false,
    this.studyCount = 0,
    this.lastStudiedAt,
    this.noteId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'answer': answer,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isStudied': isStudied,
      'studyCount': studyCount,
      'lastStudiedAt': lastStudiedAt != null ? Timestamp.fromDate(lastStudiedAt!) : null,
      'noteId': noteId,
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isStudied: map['isStudied'] ?? false,
      studyCount: map['studyCount'] ?? 0,
      lastStudiedAt: map['lastStudiedAt'] != null 
          ? (map['lastStudiedAt'] as Timestamp).toDate()
          : null,
      noteId: map['noteId'],
    );
  }

  FlashcardModel copyWith({
    String? id,
    String? userId,
    String? question,
    String? answer,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStudied,
    int? studyCount,
    DateTime? lastStudiedAt,
    String? noteId,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStudied: isStudied ?? this.isStudied,
      studyCount: studyCount ?? this.studyCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      noteId: noteId ?? this.noteId,
    );
  }
} 