import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String userId;
  final String title;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final int timeLimit; // in minutes

  QuizModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.questions,
    required this.createdAt,
    this.timeLimit = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'timeLimit': timeLimit,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      questions: (map['questions'] as List)
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeLimit: map['timeLimit'] ?? 10,
    );
  }
}

class QuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      correctAnswer: map['correctAnswer'] ?? '',
      options: List<String>.from(map['options'] ?? []),
    );
  }
}

class QuizAttempt {
  final String id;
  final String userId;
  final String quizId;
  final int score;
  final int totalQuestions;
  final DateTime attemptedAt;
  final int timeTaken; // in seconds
  final List<QuizAnswer> answers;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.attemptedAt,
    required this.timeTaken,
    required this.answers,
  });

  double get percentage => (score / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'attemptedAt': Timestamp.fromDate(attemptedAt),
      'timeTaken': timeTaken,
      'answers': answers.map((a) => a.toMap()).toList(),
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      quizId: map['quizId'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      attemptedAt: (map['attemptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeTaken: map['timeTaken'] ?? 0,
      answers: (map['answers'] as List)
          .map((a) => QuizAnswer.fromMap(a))
          .toList(),
    );
  }
}

class QuizAnswer {
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuizAnswer({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
    };
  }

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      question: map['question'] ?? '',
      selectedAnswer: map['selectedAnswer'] ?? '',
      correctAnswer: map['correctAnswer'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
} 