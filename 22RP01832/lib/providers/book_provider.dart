import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Book> get books => _books;

  Future<void> fetchBooks() async {
    final snapshot = await FirebaseFirestore.instance.collection('books').get();
    _books = snapshot.docs
        .map((doc) => Book.fromMap(doc.data(), doc.id))
        .toList();
    // Sort by createdAt descending in Dart
    _books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    final docRef = await FirebaseFirestore.instance
        .collection('books')
        .add(book.toMap());
    final newBook = book.copyWith(id: docRef.id);
    _books.insert(0, newBook);
    notifyListeners();
  }

  List<Book> searchBooks(String query) {
    query = query.toLowerCase();
    return _books
        .where(
          (book) =>
              book.title.toLowerCase().contains(query) ||
              book.subject.toLowerCase().contains(query) ||
              book.price.toString().contains(query),
        )
        .toList();
  }
}
