import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import 'api/book_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class BookService {
  static const String _booksBoxName = 'books';
  static const String _favoritesBoxName = 'favorites';
  static const String _readingProgressBoxName = 'reading_progress';
  static const String _downloadsBoxName = 'downloads';
  
  late Box<Book> _booksBox;
  late Box<String> _favoritesBox;
  late Box<Map> _readingProgressBox;
  late Box<String> _downloadsBox;
  
  final BookApiService _apiService = BookApiService();
  
  bool _isInitialized = false;

  // Initialize Hive and boxes
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookAdapter());
    }
    
    // Open boxes
    _booksBox = await Hive.openBox<Book>(_booksBoxName);
    _favoritesBox = await Hive.openBox<String>(_favoritesBoxName);
    _readingProgressBox = await Hive.openBox<Map>(_readingProgressBoxName);
    _downloadsBox = await Hive.openBox<String>(_downloadsBoxName);
    
    _isInitialized = true;
  }

  // Search books from API
  Future<List<Book>> searchBooks({
    required String query,
    String? language,
    String? category,
    String? source,
    int maxResults = 20,
  }) async {
    await initialize();
    return await _apiService.searchBooks(
      query: query,
      language: language,
      category: category,
      source: source,
      maxResults: maxResults,
    );
  }

  // Get book details
  Future<Book?> getBookDetails(String bookId, String source) async {
    await initialize();
    return await _apiService.getBookDetails(bookId, source);
  }

  // Save book to local storage
  Future<void> saveBook(Book book) async {
    await initialize();
    await _booksBox.put(book.id, book);
  }

  // Get book from local storage
  Book? getBook(String bookId) {
    return _booksBox.get(bookId);
  }

  // Get all saved books
  List<Book> getAllBooks() {
    return _booksBox.values.toList();
  }

  // Add book to favorites
  Future<void> addToFavorites(String bookId) async {
    await initialize();
    await _favoritesBox.put(bookId, bookId);
    
    // Update book's favorite status
    final book = _booksBox.get(bookId);
    if (book != null) {
      await _booksBox.put(bookId, book.copyWith(isFavorite: true));
    }
  }

  // Remove book from favorites
  Future<void> removeFromFavorites(String bookId) async {
    await initialize();
    await _favoritesBox.delete(bookId);
    
    // Update book's favorite status
    final book = _booksBox.get(bookId);
    if (book != null) {
      await _booksBox.put(bookId, book.copyWith(isFavorite: false));
    }
  }

  // Get all favorite books
  List<Book> getFavoriteBooks() {
    final favoriteIds = _favoritesBox.values.toList();
    return favoriteIds
        .map((id) => _booksBox.get(id))
        .where((book) => book != null)
        .cast<Book>()
        .toList();
  }

  // Check if book is favorite
  bool isFavorite(String bookId) {
    return _favoritesBox.containsKey(bookId);
  }

  // Update reading progress
  Future<void> updateReadingProgress({
    required String bookId,
    required int currentPage,
    required double progress,
  }) async {
    await initialize();
    
    final progressData = {
      'currentPage': currentPage,
      'progress': progress,
      'lastReadAt': DateTime.now().toIso8601String(),
    };
    
    await _readingProgressBox.put(bookId, progressData);
    
    // Update book's reading progress
    final book = _booksBox.get(bookId);
    if (book != null) {
      await _booksBox.put(bookId, book.copyWith(
        lastPageRead: currentPage,
        readingProgress: progress,
        lastReadAt: DateTime.now(),
      ));
    }
  }

  // Get reading progress
  Map<String, dynamic>? getReadingProgress(String bookId) {
    final progress = _readingProgressBox.get(bookId);
    if (progress != null) {
      return Map<String, dynamic>.from(progress);
    }
    return null;
  }

  // Get all books with reading progress
  List<Book> getBooksWithProgress() {
    return _booksBox.values
        .where((book) => book.readingProgress != null && book.readingProgress! > 0)
        .toList()
      ..sort((a, b) => (b.lastReadAt ?? DateTime(1900)).compareTo(a.lastReadAt ?? DateTime(1900)));
  }

  // Add bookmark
  Future<void> addBookmark(String bookId, String pageOrPosition) async {
    await initialize();
    
    final book = _booksBox.get(bookId);
    if (book != null) {
      final bookmarks = List<String>.from(book.bookmarks);
      if (!bookmarks.contains(pageOrPosition)) {
        bookmarks.add(pageOrPosition);
        await _booksBox.put(bookId, book.copyWith(bookmarks: bookmarks));
      }
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String bookId, String pageOrPosition) async {
    await initialize();
    
    final book = _booksBox.get(bookId);
    if (book != null) {
      final bookmarks = List<String>.from(book.bookmarks);
      bookmarks.remove(pageOrPosition);
      await _booksBox.put(bookId, book.copyWith(bookmarks: bookmarks));
    }
  }

  // Get bookmarks for a book
  List<String> getBookmarks(String bookId) {
    final book = _booksBox.get(bookId);
    return book?.bookmarks ?? [];
  }

  // Download book
  Future<bool> downloadBook(Book book) async {
    await initialize();
    if (kIsWeb) {
      if (book.downloadLink != null) {
        await launchUrl(Uri.parse(book.downloadLink!), mode: LaunchMode.externalApplication);
        // Mark as downloaded in Hive for tracking (any format)
        await _downloadsBox.put(book.id, book.downloadLink!);
        await _booksBox.put(book.id, book.copyWith(
          isDownloaded: true,
          localPath: book.downloadLink,
        ));
        return true;
      } else {
        return false;
      }
    }
    try {
      if (book.downloadLink == null) return false;
      
      // Create downloads directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        print('Downloads directory not available');
        return false;
      }
      final booksDir = Directory('${downloadsDir.path}/RwandaRead/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }
      
      // Download file
      final fileName = '${book.id}.${book.format?.toLowerCase() ?? 'pdf'}';
      final filePath = '${booksDir.path}/$fileName';
      
      // For now, we'll just save the download link
      // In a real app, you'd implement actual file download
      await _downloadsBox.put(book.id, filePath);
      
      // Update book status
      await _booksBox.put(book.id, book.copyWith(
        isDownloaded: true,
        localPath: filePath,
      ));
      
      return true;
    } catch (e) {
      print('Error downloading book: $e');
      return false;
    }
  }

  // Get downloaded books
  List<Book> getDownloadedBooks() {
    return _booksBox.values
        .where((book) => book.isDownloaded)
        .toList();
  }

  // Check if book is downloaded
  bool isDownloaded(String bookId) {
    return _downloadsBox.containsKey(bookId);
  }

  // Get local file path for downloaded book
  String? getLocalFilePath(String bookId) {
    return _downloadsBox.get(bookId);
  }

  // Delete downloaded book
  Future<void> deleteDownloadedBook(String bookId) async {
    await initialize();
    
    final filePath = _downloadsBox.get(bookId);
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    await _downloadsBox.delete(bookId);
    
    // Update book status
    final book = _booksBox.get(bookId);
    if (book != null) {
      await _booksBox.put(bookId, book.copyWith(
        isDownloaded: false,
        localPath: null,
      ));
    }
  }

  // Get recently read books
  List<Book> getRecentlyReadBooks({int limit = 10}) {
    return getBooksWithProgress()
        .take(limit)
        .toList();
  }

  // Get books by category
  List<Book> getBooksByCategory(String category) {
    return _booksBox.values
        .where((book) => book.categories.any((cat) => 
            cat.toLowerCase().contains(category.toLowerCase())))
        .toList();
  }

  // Get books by language
  List<Book> getBooksByLanguage(String language) {
    return _booksBox.values
        .where((book) => book.language?.toLowerCase() == language.toLowerCase())
        .toList();
  }

  // Get Kinyarwanda books
  List<Book> getKinyarwandaBooks() {
    return _booksBox.values
        .where((book) => book.isKinyarwanda)
        .toList();
  }

  // Search local books
  List<Book> searchLocalBooks(String query) {
    final normalizedQuery = query.toLowerCase();
    return _booksBox.values
        .where((book) => 
            book.title.toLowerCase().contains(normalizedQuery) ||
            book.authors.any((author) => 
                author.toLowerCase().contains(normalizedQuery)) ||
            book.categories.any((category) => 
                category.toLowerCase().contains(normalizedQuery)))
        .toList();
  }

  // Get reading statistics
  Future<Map<String, dynamic>> getReadingStatistics() async {
    await initialize();
    
    final allBooks = _booksBox.values.toList();
    final booksWithProgress = allBooks.where((book) => 
        book.readingProgress != null && book.readingProgress! > 0).toList();
    
    int totalBooksRead = booksWithProgress.length;
    double totalProgress = booksWithProgress.fold(0.0, (sum, book) => 
        sum + (book.readingProgress ?? 0.0));
    double averageProgress = totalBooksRead > 0 ? totalProgress / totalBooksRead : 0.0;
    
    int totalPagesRead = booksWithProgress.fold(0, (sum, book) => 
        sum + (book.lastPageRead ?? 0));
    
    return {
      'totalBooksRead': totalBooksRead,
      'totalBooks': allBooks.length,
      'averageProgress': averageProgress,
      'totalPagesRead': totalPagesRead,
      'favoriteBooks': getFavoriteBooks().length,
      'downloadedBooks': getDownloadedBooks().length,
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    await initialize();
    await _booksBox.clear();
    await _favoritesBox.clear();
    await _readingProgressBox.clear();
    await _downloadsBox.clear();
  }

  // Close boxes
  Future<void> close() async {
    await _booksBox.close();
    await _favoritesBox.close();
    await _readingProgressBox.close();
    await _downloadsBox.close();
  }

  Future<void> addFavorite(Book book) async {
    await saveBook(book);
    await addToFavorites(book.id);
  }
  Future<void> removeFavorite(String bookId) async {
    await removeFromFavorites(bookId);
  }

  File getLocalFile(String path) {
    return File(path);
  }
} 