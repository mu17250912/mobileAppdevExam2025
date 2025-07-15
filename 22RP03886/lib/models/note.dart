class Note {
  final String? docId; // Firestore document ID
  final int? id;
  final String title;
  final String content;
  final DateTime dateCreated;

  Note({
    this.docId,
    this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
  });

  // Add toMap/fromMap for SQLite
} 