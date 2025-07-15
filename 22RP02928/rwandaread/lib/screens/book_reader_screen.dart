import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;
  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final BookService _bookService = BookService();
  String? _bookText;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  List<String> _pages = [];
  List<String> _bookmarks = [];
  static const int linesPerPage = 30;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    await _bookService.initialize();
    _bookmarks = _bookService.getBookmarks(widget.book.id);
    int? lastPage = widget.book.lastPageRead;
    if (widget.book.isDownloaded && widget.book.localPath != null) {
      if (widget.book.format?.toLowerCase() == 'txt') {
        // Load text file and split into pages
        try {
          final file = await _bookService.getLocalFile(widget.book.localPath!);
          _bookText = await file.readAsString();
          _pages = _splitTextIntoPages(_bookText!);
          _totalPages = _pages.length;
          _currentPage = (lastPage != null && lastPage > 0 && lastPage <= _totalPages) ? lastPage : 1;
        } catch (e) {
          _bookText = 'Failed to load book text.';
          _pages = [_bookText!];
        }
      } else if (widget.book.format?.toLowerCase() == 'pdf') {
        // Open PDF in browser
        await launchUrl(Uri.file(widget.book.localPath!), mode: LaunchMode.externalApplication);
        Navigator.pop(context);
        return;
      } else if (widget.book.format?.toLowerCase() == 'epub') {
        // EPUB: open in browser or show unsupported message
        try {
          await launchUrl(Uri.file(widget.book.localPath!), mode: LaunchMode.externalApplication);
        } catch (e) {
          setState(() {
            _bookText = 'EPUB reading is not supported in-app. File opened in browser.';
            _pages = [_bookText!];
          });
        }
        Navigator.pop(context);
        return;
      }
    } else {
      // Not downloaded: open preview/download link
      final url = widget.book.previewLink ?? widget.book.downloadLink;
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        Navigator.pop(context);
        return;
      } else {
        _bookText = 'No preview or download link available.';
        _pages = [_bookText!];
      }
    }
    setState(() => _isLoading = false);
    // Ensure book is marked as read if not already
    final book = _bookService.getBook(widget.book.id);
    if (book != null && (book.readingProgress == null || book.readingProgress == 0.0)) {
      await _bookService.updateReadingProgress(
        bookId: widget.book.id,
        currentPage: 1,
        progress: 0.01,
      );
    }
  }

  List<String> _splitTextIntoPages(String text) {
    final lines = text.split('\n');
    List<String> pages = [];
    for (int i = 0; i < lines.length; i += linesPerPage) {
      pages.add(lines.sublist(i, (i + linesPerPage > lines.length) ? lines.length : i + linesPerPage).join('\n'));
    }
    return pages.isEmpty ? [text] : pages;
  }

  void _addBookmark() async {
    await _bookService.addBookmark(widget.book.id, 'Page $_currentPage');
    setState(() {
      _bookmarks = _bookService.getBookmarks(widget.book.id);
    });
  }

  void _removeBookmark(String bookmark) async {
    await _bookService.removeBookmark(widget.book.id, bookmark);
    setState(() {
      _bookmarks = _bookService.getBookmarks(widget.book.id);
    });
  }

  void _updateProgress() async {
    double progress = _totalPages > 0 ? _currentPage / _totalPages : 1.0;
    await _bookService.updateReadingProgress(
      bookId: widget.book.id,
      currentPage: _currentPage,
      progress: progress,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress updated!')));
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _updateProgress();
      // Show notification if user reaches the last page
      if (page == _totalPages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Congratulations! You’ve finished reading this book.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookText != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(_pages.isNotEmpty ? _pages[_currentPage - 1] : _bookText!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                          ),
                          Text('Page $_currentPage / $_totalPages'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_bookmarks.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bookmarks:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._bookmarks.map((b) => ListTile(
                                  title: Text(b),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeBookmark(b),
                                  ),
                                )),
                          ],
                        ),
                    ],
                  ),
                )
              : const Center(child: Text('No content available.')),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Add Bookmark'),
              onPressed: () async {
                await _bookService.addBookmark(widget.book.id, 'Page $_currentPage');
                setState(() {
                  _bookmarks = _bookService.getBookmarks(widget.book.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added!')),
                );
              },
            ),
    );
  }
} 