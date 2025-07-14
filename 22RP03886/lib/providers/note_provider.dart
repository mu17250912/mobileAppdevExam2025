import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/db_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    if (kIsWeb) {
      final snapshot = await FirebaseFirestore.instance.collection('notes').orderBy('dateCreated').get();
      _notes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Note(
          docId: doc.id,
          id: null,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          dateCreated: DateTime.parse(data['dateCreated']),
        );
      }).toList();
    } else {
      final data = await DBHelper.getNotes();
      _notes = data.map((e) => Note(
        id: e['id'],
        title: e['title'],
        content: e['content'],
        dateCreated: DateTime.parse(e['dateCreated']),
      )).toList();
    }
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    if (kIsWeb) {
      await FirebaseFirestore.instance.collection('notes').add({
        'title': note.title,
        'content': note.content,
        'dateCreated': note.dateCreated.toIso8601String(),
      });
    } else {
      await DBHelper.insertNote(note);
    }
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    if (kIsWeb) {
      if (note.docId == null) return;
      await FirebaseFirestore.instance.collection('notes').doc(note.docId).update({
        'title': note.title,
        'content': note.content,
        'dateCreated': note.dateCreated.toIso8601String(),
      });
      await loadNotes();
    } else {
      await DBHelper.updateNote(note);
      await loadNotes();
    }
  }

  Future<void> deleteNote(dynamic noteOrId) async {
    if (kIsWeb) {
      String? docId;
      if (noteOrId is Note) {
        docId = noteOrId.docId;
      } else if (noteOrId is String) {
        docId = noteOrId;
      }
      if (docId == null) return;
      await FirebaseFirestore.instance.collection('notes').doc(docId).delete();
      await loadNotes();
    } else {
      int? id;
      if (noteOrId is Note) {
        id = noteOrId.id;
      } else if (noteOrId is int) {
        id = noteOrId;
      }
      if (id == null) return;
      await DBHelper.deleteNote(id);
      await loadNotes();
    }
  }
} 