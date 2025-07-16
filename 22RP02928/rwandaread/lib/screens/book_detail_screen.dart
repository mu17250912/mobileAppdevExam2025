import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/subscription_service.dart';
import 'book_reader_screen.dart';
import 'bookmarks_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  Book? _book;
  bool _isFavorite = false;
  bool _isDownloaded = false;
  bool _isLoading = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initBookService();
  }

  Future<void> _initBookService() async {
    await _bookService.initialize();
    final isSubscribed = await _subscriptionService.isUserSubscribed();
    setState(() {
      _book = widget.book;
      _isSubscribed = isSubscribed;
      _isLoading = false;
    });
    _refreshState();
  }

  void _refreshState() {
    if (_book == null) return;
    setState(() {
      _isFavorite = _bookService.isFavorite(_book!.id);
      _isDownloaded = _bookService.isDownloaded(_book!.id);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_book == null) return;
    setState(() => _isLoading = true);
    if (_isFavorite) {
      await _bookService.removeFavorite(_book!.id);
    } else {
      await _bookService.addFavorite(_book!);
    }
    _refreshState();
    setState(() => _isLoading = false);
  }

  Future<void> _downloadBook() async {
    if (_book == null) return;
    
    // Check subscription for premium features
    if (!_isSubscribed) {
      _showPremiumDialog();
      return;
    }
    
    setState(() => _isLoading = true);
    if (_book!.downloadLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No downloadable file available for this book.')));
      setState(() => _isLoading = false);
      return;
    }
    final success = await _bookService.downloadBook(_book!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book downloaded or opened in new tab')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed')));
    }
    _refreshState();
    setState(() => _isLoading = false);
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Downloading books is a premium feature. Upgrade to unlock unlimited downloads and other premium features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  void _openReader() async {
    if (_book == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookReaderScreen(book: _book!)),
    );
    _refreshState();
  }

  void _openBookmarks() {
    if (_book == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookmarksScreen(book: _book!)),
    );
  }

  Future<void> _readOnline() async {
    if (_book == null) return;
    if (_book!.downloadLink != null) {
      await launchUrl(Uri.parse(_book!.downloadLink!), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No direct file available for this book.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Details'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(),
            const SizedBox(height: 24),
            _buildBookInfo(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: Icon(_isDownloaded ? Icons.download_done : Icons.download),
                  tooltip: _book!.downloadLink == null ? 'PDF not available for this book.' : (_isDownloaded ? 'Downloaded' : 'Download PDF'),
                  onPressed: (_isDownloaded || _book!.downloadLink == null)
                      ? () {
                          if (_book!.downloadLink == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF not available for this book.')));
                          }
                        }
                      : _downloadBook,
                ),
                IconButton(
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Read',
                  onPressed: _openReader,
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark),
                  tooltip: 'Bookmarks',
                  onPressed: _openBookmarks,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_book!.downloadLink != null)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Read Online (PDF)'),
                  onPressed: _readOnline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (_book!.downloadLink == null)
              Center(
                child: Text('No direct file available for this book.', style: TextStyle(color: Colors.red[400])),
              ),
            const SizedBox(height: 24),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeader() {
    if (_book == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Book cover
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _book!.coverImage != null
                  ? Image.network(
                      _book!.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.book,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.book,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Book title
          Text(
            _book!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Author
          Text(
            _book!.authorNames,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Rating
          if (_book!.averageRating != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber[300],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _book!.averageRating!.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_book!.ratingsCount ?? 0} ratings)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    if (_book == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Language', _book!.language ?? 'Unknown'),
          _buildInfoRow('Pages', _book!.formattedPageCount),
          _buildInfoRow('Published', _book!.formattedPublishedDate),
          _buildInfoRow('Publisher', _book!.publisher ?? 'Unknown'),
          _buildInfoRow('Format', _book!.format ?? 'Unknown'),
          _buildInfoRow('Source', _book!.source ?? 'Unknown'),
          if (_book!.categories.isNotEmpty)
            _buildInfoRow('Categories', _book!.categoryNames),
          if (_book!.readingProgress != null && _book!.readingProgress! > 0)
            _buildInfoRow('Progress', '${(_book!.readingProgress! * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (_book == null) return const SizedBox.shrink();
    if (_book!.description == null || _book!.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _book!.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 