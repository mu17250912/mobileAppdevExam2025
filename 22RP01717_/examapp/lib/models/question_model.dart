class QuestionModel {
  final String id;
  final String categoryId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data) {
    return QuestionModel(
      id: data['id'],
      categoryId: data['categoryId'],
      question: data['question'],
      options: List<String>.from(data['options']),
      correctIndex: data['correctIndex'],
      explanation: data['explanation'],
    );
  }
} 