import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';

class HomeworkService {
  static final _collection = FirebaseFirestore.instance.collection('homework');

  static Future<void> addHomework(Homework homework) async {
    await _collection.add(homework.toMap());
  }

  static Future<List<Homework>> getHomeworkForClass(String className) async {
    final snapshot = await _collection.where('class', isEqualTo: className).orderBy('dueDate').get();
    return snapshot.docs.map((doc) => Homework.fromMap(doc.id, doc.data())).toList();
  }

  static Future<List<Homework>> getHomeworkForTeacher(String teacherId) async {
    final snapshot = await _collection.where('teacherId', isEqualTo: teacherId).orderBy('dueDate').get();
    return snapshot.docs.map((doc) => Homework.fromMap(doc.id, doc.data())).toList();
  }
} 