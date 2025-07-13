import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'book_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final Book book;
  const BookmarksScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookService _bookService = BookService();
  List<String> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    await _bookService.initialize();
    setState(() {
      _bookmarks = _bookService.getBookmarks(widget.book.id);
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(String bookmark) async {
    await _bookService.removeBookmark(widget.book.id, bookmark);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No bookmarks yet.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Read & Add Bookmark'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookReaderScreen(book: widget.book),
                            ),
                          );
                          _loadBookmarks();
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Add bookmarks while reading!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    return ListTile(
                      title: Text('Page/Position: $bookmark'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeBookmark(bookmark),
                      ),
                    );
                  },
                ),
    );
  }
} 