import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/subscription_service.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BookService _bookService = BookService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Book> _searchResults = [];
  List<Book> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSubscribed = false;
  String? _selectedLanguage;
  String? _selectedCategory;
  String? _selectedSource;
  final List<String> _languages = ['All', 'English', 'Kinyarwanda', 'French'];
  final List<String> _sources = ['All', 'Google Books', 'Open Library', 'Project Gutenberg'];
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _initBookService();
  }

  Future<void> _initBookService() async {
    await _bookService.initialize();
    final isSubscribed = await _subscriptionService.isUserSubscribed();
    _loadRecentSearches();
    _categories = ['All', ..._getAllCategories()];
    setState(() {
      _isSubscribed = isSubscribed;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      await _bookService.initialize();
      final recentBooks = _bookService.getRecentlyReadBooks(limit: 5);
      setState(() {
        _recentSearches = recentBooks;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      String? languageFilter;
      if (_selectedLanguage != null && _selectedLanguage != 'All') {
        switch (_selectedLanguage) {
          case 'English': languageFilter = 'en'; break;
          case 'Kinyarwanda': languageFilter = 'rw'; break;
          case 'French': languageFilter = 'fr'; break;
        }
      }
      final results = await _bookService.searchBooks(
        query: _searchController.text.trim(),
        language: languageFilter,
        category: _selectedCategory,
        source: _selectedSource,
        maxResults: 30,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getAllCategories() {
    // TODO: Load categories from local books or a static list
    return ['Fiction', 'Non-fiction', 'Children', 'Education', 'History', 'Science'];
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Unlock unlimited searches and premium features',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedLanguage = null;
      _selectedCategory = null;
      _selectedSource = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Premium Banner
          if (!_isSubscribed) _buildPremiumBanner(),
          // Search Bar - Always visible at the top
          _buildSearchBar(),
          // Filters
          _buildFilters(),
          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for books, authors, or topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E3A8A),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _languages.map((language) {
                return DropdownMenuItem(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildRecentSearches();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E3A8A),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildBookCard(_searchResults[index]);
      },
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recently Read',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map((book) => _buildBookCard(book)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for books',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find thousands of free books from multiple sources',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No books found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: book.coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          book.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.book,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.book,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.authors.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.authors.join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (book.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (book.language != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              book.language!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (book.pageCount != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${book.pageCount} pages',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 