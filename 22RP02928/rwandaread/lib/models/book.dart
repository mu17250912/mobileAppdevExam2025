import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> authors;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? coverImage;

  @HiveField(5)
  final List<String> categories;

  @HiveField(6)
  final String? language;

  @HiveField(7)
  final int? pageCount;

  @HiveField(8)
  final String? publisher;

  @HiveField(9)
  final DateTime? publishedDate;

  @HiveField(10)
  final double? averageRating;

  @HiveField(11)
  final int? ratingsCount;

  @HiveField(12)
  final String? previewLink;

  @HiveField(13)
  final String? downloadLink;

  @HiveField(14)
  final String? format; // PDF, EPUB, TXT, etc.

  @HiveField(15)
  final String? source; // Google Books, Open Library, Gutendex

  @HiveField(16)
  final bool isDownloaded;

  @HiveField(17)
  final String? localPath;

  @HiveField(18)
  final bool isFavorite;

  @HiveField(19)
  final DateTime? lastReadAt;

  @HiveField(20)
  final int? lastPageRead;

  @HiveField(21)
  final double? readingProgress; // 0.0 to 1.0

  @HiveField(22)
  final List<String> bookmarks; // List of page numbers or positions

  @HiveField(23)
  final DateTime createdAt;

  @HiveField(24)
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.coverImage,
    this.categories = const [],
    this.language,
    this.pageCount,
    this.publisher,
    this.publishedDate,
    this.averageRating,
    this.ratingsCount,
    this.previewLink,
    this.downloadLink,
    this.format,
    this.source,
    this.isDownloaded = false,
    this.localPath,
    this.isFavorite = false,
    this.lastReadAt,
    this.lastPageRead,
    this.readingProgress = 0.0,
    this.bookmarks = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a copy of the book with updated fields
  Book copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? description,
    String? coverImage,
    List<String>? categories,
    String? language,
    int? pageCount,
    String? publisher,
    DateTime? publishedDate,
    double? averageRating,
    int? ratingsCount,
    String? previewLink,
    String? downloadLink,
    String? format,
    String? source,
    bool? isDownloaded,
    String? localPath,
    bool? isFavorite,
    DateTime? lastReadAt,
    int? lastPageRead,
    double? readingProgress,
    List<String>? bookmarks,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      previewLink: previewLink ?? this.previewLink,
      downloadLink: downloadLink ?? this.downloadLink,
      format: format ?? this.format,
      source: source ?? this.source,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      lastPageRead: lastPageRead ?? this.lastPageRead,
      readingProgress: readingProgress ?? this.readingProgress,
      bookmarks: bookmarks ?? this.bookmarks,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'coverImage': coverImage,
      'categories': categories,
      'language': language,
      'pageCount': pageCount,
      'publisher': publisher,
      'publishedDate': publishedDate?.toIso8601String(),
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'previewLink': previewLink,
      'downloadLink': downloadLink,
      'format': format,
      'source': source,
      'isDownloaded': isDownloaded,
      'localPath': localPath,
      'isFavorite': isFavorite,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'lastPageRead': lastPageRead,
      'readingProgress': readingProgress,
      'bookmarks': bookmarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (JSON deserialization)
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      authors: List<String>.from(json['authors'] ?? []),
      description: json['description'],
      coverImage: json['coverImage'],
      categories: List<String>.from(json['categories'] ?? []),
      language: json['language'],
      pageCount: json['pageCount'],
      publisher: json['publisher'],
      publishedDate: json['publishedDate'] != null 
          ? DateTime.parse(json['publishedDate']) 
          : null,
      averageRating: json['averageRating']?.toDouble(),
      ratingsCount: json['ratingsCount'],
      previewLink: json['previewLink'],
      downloadLink: json['downloadLink'],
      format: json['format'],
      source: json['source'],
      isDownloaded: json['isDownloaded'] ?? false,
      localPath: json['localPath'],
      isFavorite: json['isFavorite'] ?? false,
      lastReadAt: json['lastReadAt'] != null 
          ? DateTime.parse(json['lastReadAt']) 
          : null,
      lastPageRead: json['lastPageRead'],
      readingProgress: json['readingProgress']?.toDouble() ?? 0.0,
      bookmarks: List<String>.from(json['bookmarks'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Get author names as a single string
  String get authorNames => authors.join(', ');

  // Get categories as a single string
  String get categoryNames => categories.join(', ');

  // Check if book is in Kinyarwanda
  bool get isKinyarwanda => language?.toLowerCase() == 'rw' || 
                           language?.toLowerCase() == 'kin' ||
                           language?.toLowerCase() == 'kinyarwanda';

  // Get reading status
  String get readingStatus {
    if (readingProgress == null || readingProgress == 0.0) {
      return 'Not Started';
    } else if (readingProgress! < 0.1) {
      return 'Just Started';
    } else if (readingProgress! < 0.5) {
      return 'In Progress';
    } else if (readingProgress! < 0.9) {
      return 'Almost Done';
    } else {
      return 'Completed';
    }
  }

  // Get formatted rating
  String get formattedRating {
    if (averageRating == null) return 'No ratings';
    return '${averageRating!.toStringAsFixed(1)} (${ratingsCount ?? 0} ratings)';
  }

  // Get formatted page count
  String get formattedPageCount {
    if (pageCount == null) return 'Unknown pages';
    return '$pageCount pages';
  }

  // Get formatted published date
  String get formattedPublishedDate {
    if (publishedDate == null) return 'Unknown date';
    return '${publishedDate!.year}';
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, authors: $authors)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 