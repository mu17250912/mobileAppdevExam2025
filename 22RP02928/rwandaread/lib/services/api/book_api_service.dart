import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/book.dart';

class BookApiService {
  final Dio _dio = Dio();
  
  // API Base URLs
  static const String _googleBooksBaseUrl = 'https://www.googleapis.com/books/v1';
  static const String _openLibraryBaseUrl = 'https://openlibrary.org';
  static const String _gutendexBaseUrl = 'https://gutendex.com';

  BookApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Search books from multiple sources
  Future<List<Book>> searchBooks({
    required String query,
    String? language,
    String? category,
    String? source,
    int maxResults = 20,
  }) async {
    List<Book> allBooks = [];
    try {
      // Determine which sources to search
      final searchGoogle = (source == null || source == 'Google Books' || source == 'All');
      final searchOpenLibrary = (source == null || source == 'Open Library' || source == 'All');
      final searchGutendex = (source == null || source == 'Project Gutenberg' || source == 'All');
      final futures = <Future<List<Book>>>[];
      if (searchGoogle) futures.add(_searchGoogleBooks(query, language, category, maxResults));
      if (searchOpenLibrary) futures.add(_searchOpenLibrary(query, language, category, maxResults));
      if (searchGutendex) futures.add(_searchGutendex(query, language, category, maxResults));
      final results = await Future.wait(futures);
      for (final books in results) {
        allBooks.addAll(books);
      }
      allBooks = _removeDuplicates(allBooks);
      allBooks.sort((a, b) {
        bool aExactMatch = a.title.toLowerCase().contains(query.toLowerCase());
        bool bExactMatch = b.title.toLowerCase().contains(query.toLowerCase());
        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;
        if (a.averageRating != null && b.averageRating != null) {
          if (a.averageRating! != b.averageRating!) {
            return b.averageRating!.compareTo(a.averageRating!);
          }
        }
        if (a.publishedDate != null && b.publishedDate != null) {
          return b.publishedDate!.compareTo(a.publishedDate!);
        }
        return 0;
      });
      // Filter by category if selected
      if (category != null && category.isNotEmpty) {
        allBooks = allBooks.where((b) => b.categories.any((c) => c.toLowerCase().contains(category.toLowerCase()))).toList();
      }
      return allBooks.take(maxResults).toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  Future<List<Book>> _searchGoogleBooks(String query, String? language, String? category, int maxResults) async {
    try {
      final response = await _dio.get(
        '$_googleBooksBaseUrl/volumes',
        queryParameters: {
          'q': category != null && category.isNotEmpty ? '$query+subject:$category' : query,
          'maxResults': maxResults,
          'orderBy': 'relevance',
          if (language != null) 'langRestrict': language,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = data['items'] as List?;
        if (items == null) return [];
        return items.map((item) => _parseGoogleBook(item)).toList();
      }
    } catch (e) {
      print('Error searching Google Books: $e');
    }
    return [];
  }

  // Parse Google Books response
  Book _parseGoogleBook(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] ?? {};
    final saleInfo = item['saleInfo'] ?? {};
    
    return Book(
      id: item['id'] ?? '',
      title: volumeInfo['title'] ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? []),
      description: volumeInfo['description'],
      coverImage: volumeInfo['imageLinks']?['thumbnail'],
      categories: List<String>.from(volumeInfo['categories'] ?? []),
      language: volumeInfo['language'],
      pageCount: volumeInfo['pageCount'],
      publisher: volumeInfo['publisher'],
      publishedDate: volumeInfo['publishedDate'] != null 
          ? DateTime.tryParse(volumeInfo['publishedDate']) 
          : null,
      averageRating: volumeInfo['averageRating']?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'],
      previewLink: volumeInfo['previewLink'],
      downloadLink: saleInfo['buyLink'],
      format: 'PDF',
      source: 'Google Books',
    );
  }

  Future<List<Book>> _searchOpenLibrary(String query, String? language, String? category, int maxResults) async {
    try {
      final response = await _dio.get(
        '$_openLibraryBaseUrl/search.json',
        queryParameters: {
          'q': query,
          'limit': maxResults,
          if (language != null) 'language': language,
          if (category != null && category.isNotEmpty) 'subject': category,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final docs = data['docs'] as List?;
        if (docs == null) return [];
        return docs.map((doc) => _parseOpenLibraryBook(doc)).toList();
      }
    } catch (e) {
      print('Error searching Open Library: $e');
    }
    return [];
  }

  // Parse Open Library response
  Book _parseOpenLibraryBook(Map<String, dynamic> doc) {
    final authorNames = (doc['author_name'] as List?)?.cast<String>() ?? [];
    
    return Book(
      id: 'ol_${doc['key']}',
      title: doc['title'] ?? 'Unknown Title',
      authors: authorNames.cast<String>(),
      description: doc['first_sentence']?.first,
      coverImage: doc['cover_i'] != null 
          ? 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-L.jpg'
          : null,
      categories: List<String>.from(doc['subject'] ?? []),
      language: doc['language']?.first,
      pageCount: doc['number_of_pages_median'],
      publisher: doc['publisher']?.first,
      publishedDate: doc['first_publish_year'] != null 
          ? DateTime(doc['first_publish_year']) 
          : null,
      averageRating: doc['ratings_average']?.toDouble(),
      ratingsCount: doc['ratings_count'],
      previewLink: 'https://openlibrary.org${doc['key']}',
      downloadLink: doc['ebook_access'] == 'borrowable' 
          ? 'https://openlibrary.org${doc['key']}/ebook'
          : null,
      format: 'EPUB',
      source: 'Open Library',
    );
  }

  Future<List<Book>> _searchGutendex(String query, String? language, String? category, int maxResults) async {
    try {
      final response = await _dio.get(
        '$_gutendexBaseUrl/books',
        queryParameters: {
          'search': query,
          'languages': language ?? 'en',
          if (category != null && category.isNotEmpty) 'topic': category,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] as List?;
        if (results == null) return [];
        return results.take(maxResults).map((result) => _parseGutendexBook(result)).toList();
      }
    } catch (e) {
      print('Error searching Gutendex: $e');
    }
    return [];
  }

  // Parse Gutendex response
  Book _parseGutendexBook(Map<String, dynamic> result) {
    final authors = (result['authors'] as List?)?.map((author) {
      return author['name'] ?? 'Unknown Author';
    }).toList().cast<String>() ?? [];

    final formats = result['formats'] ?? {};
    String? pdfLink;
    if (formats['application/pdf'] != null) {
      pdfLink = formats['application/pdf'];
    }
    // Only set downloadLink if PDF is available
    return Book(
      id: 'gutenberg_${result['id']}',
      title: result['title'] ?? 'Unknown Title',
      authors: authors,
      description: result['subjects']?.join(', '),
      coverImage: result['formats']?['image/jpeg'],
      categories: List<String>.from(result['subjects'] ?? []),
      language: result['languages']?.first,
      pageCount: null, // Gutendex doesn't provide page count
      publisher: 'Project Gutenberg',
      publishedDate: null, // Gutendex doesn't provide exact date
      averageRating: null, // Gutendex doesn't provide ratings
      ratingsCount: null,
      previewLink: result['formats']?['text/html'],
      downloadLink: pdfLink,
      format: 'PDF',
      source: 'Project Gutenberg',
    );
  }

  // Remove duplicate books based on title and author similarity
  List<Book> _removeDuplicates(List<Book> books) {
    final Map<String, Book> uniqueBooks = {};
    
    for (final book in books) {
      // Create a key based on normalized title and first author
      final normalizedTitle = book.title.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      final firstAuthor = book.authors.isNotEmpty 
          ? book.authors.first.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '')
          : '';
      final key = '$normalizedTitle|$firstAuthor';
      
      // Keep the book with more information (higher priority)
      if (!uniqueBooks.containsKey(key) || 
          _getBookPriority(book) > _getBookPriority(uniqueBooks[key]!)) {
        uniqueBooks[key] = book;
      }
    }
    
    return uniqueBooks.values.toList();
  }

  // Calculate book priority for deduplication
  int _getBookPriority(Book book) {
    int priority = 0;
    
    if (book.description != null && book.description!.isNotEmpty) priority += 10;
    if (book.coverImage != null) priority += 5;
    if (book.pageCount != null) priority += 3;
    if (book.averageRating != null) priority += 2;
    if (book.downloadLink != null) priority += 5;
    
    return priority;
  }

  // Get book details by ID
  Future<Book?> getBookDetails(String bookId, String source) async {
    try {
      switch (source) {
        case 'Google Books':
          return await _getGoogleBookDetails(bookId);
        case 'Open Library':
          return await _getOpenLibraryBookDetails(bookId);
        case 'Project Gutenberg':
          return await _getGutendexBookDetails(bookId);
        default:
          return null;
      }
    } catch (e) {
      print('Error getting book details: $e');
      return null;
    }
  }

  Future<Book?> _getGoogleBookDetails(String bookId) async {
    try {
      final response = await _dio.get('$_googleBooksBaseUrl/volumes/$bookId');
      if (response.statusCode == 200) {
        return _parseGoogleBook(response.data);
      }
    } catch (e) {
      print('Error getting Google Book details: $e');
    }
    return null;
  }

  Future<Book?> _getOpenLibraryBookDetails(String bookId) async {
    try {
      final response = await _dio.get('$_openLibraryBaseUrl$bookId.json');
      if (response.statusCode == 200) {
        return _parseOpenLibraryBook(response.data);
      }
    } catch (e) {
      print('Error getting Open Library book details: $e');
    }
    return null;
  }

  Future<Book?> _getGutendexBookDetails(String bookId) async {
    try {
      final gutenbergId = bookId.replaceFirst('gutenberg_', '');
      final response = await _dio.get('$_gutendexBaseUrl/books/$gutenbergId');
      if (response.statusCode == 200) {
        return _parseGutendexBook(response.data);
      }
    } catch (e) {
      print('Error getting Gutendex book details: $e');
    }
    return null;
  }
} 