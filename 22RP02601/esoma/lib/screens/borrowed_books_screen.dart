import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BorrowedBooksScreen extends StatelessWidget {
  const BorrowedBooksScreen({Key? key}) : super(key: key);

  Stream<List<Map<String, dynamic>>> borrowedBooksStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('borrowed_books')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'title': doc['title'] ?? 'No Title',
              'fileUrl': doc['fileUrl'] ?? '',
            }).toList());
  }

  Future<void> _openUrl(BuildContext context, String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open book info')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Borrowed Books')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: borrowedBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(child: Text('No borrowed books found for your account.'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(book['title'] ?? 'No title'),
                trailing: IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _openUrl(context, book['fileUrl'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
