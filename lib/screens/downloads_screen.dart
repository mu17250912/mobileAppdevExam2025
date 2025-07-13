import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'book_reader_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final BookService _bookService = BookService();
  late List<Book> _downloads;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    await _bookService.initialize();
    setState(() {
      _downloads = _bookService.getDownloadedBooks();
      _isLoading = false;
    });
  }

  Future<void> _refreshDownloads() async {
    setState(() => _isLoading = true);
    await _loadDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDownloads,
              child: _downloads.isEmpty
                  ? const Center(child: Text('No downloaded books yet.'))
                  : ListView.builder(
                      itemCount: _downloads.length,
                      itemBuilder: (context, index) {
                        final book = _downloads[index];
                        return ListTile(
                          leading: book.coverImage != null
                              ? Image.network(book.coverImage!, width: 40, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.book),
                          title: Text(book.title),
                          subtitle: Text(book.authors.join(', ')),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
                            );
                            _refreshDownloads();
                          },
                        );
                      },
                    ),
            ),
    );
  }
} 