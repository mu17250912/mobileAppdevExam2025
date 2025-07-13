import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'downloads_screen.dart';
import 'subscription_screen.dart';
import 'subscription_management_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final BookService _bookService = BookService();
  final UserService _userService = UserService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  List<Book> _recentlyReadBooks = [];
  List<Book> _favoriteBooks = [];
  List<Book> _downloadedBooks = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _isSubscribed = false;
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _buildHomeContent(),
      const SearchScreen(),
      const CategoriesScreen(),
      const FavoritesScreen(),
      const DownloadsScreen(),
    ]);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _bookService.initialize();
      
      final futures = <Future>[
        Future.value(_bookService.getRecentlyReadBooks(limit: 5)),
        Future.value(_bookService.getFavoriteBooks()),
        Future.value(_bookService.getDownloadedBooks()),
        _bookService.getReadingStatistics(),
        _subscriptionService.isUserSubscribed(),
      ];

      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _recentlyReadBooks = results[0] as List<Book>;
          _favoriteBooks = results[1] as List<Book>;
          _downloadedBooks = results[2] as List<Book>;
          _statistics = results[3] as Map<String, dynamic>;
          _isSubscribed = results[4] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading library data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RWANDAREAD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() => _selectedIndex = 1);
            },
            tooltip: 'Search Books',
          ),
          IconButton(
            icon: Icon(_isSubscribed ? Icons.star : Icons.star_border),
            onPressed: () {
              Navigator.pushNamed(context, '/subscription-management');
            },
            tooltip: _isSubscribed ? 'Subscription Management' : 'Get Premium',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloads'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatisticsSection(),
          const SizedBox(height: 24),
          _buildRecentlyReadSection(),
          const SizedBox(height: 24),
          _buildFavoritesSection(),
          const SizedBox(height: 24),
          _buildDownloadedSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final currentUser = _userService.getCurrentUser();
    final userName = currentUser?.displayName ?? 'Reader';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.library_books,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Discover thousands of free books',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isSubscribed)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const Text(
                          'Unlock unlimited downloads and premium features',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
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
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search Books'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to categories screen
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Categories'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Reading Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.book,
                  title: 'Books Read',
                  value: '${_statistics['totalBooksRead'] ?? 0}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  title: 'Favorites',
                  value: '${_statistics['favoriteBooks'] ?? 0}',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.download,
                  title: 'Downloaded',
                  value: '${_statistics['downloadedBooks'] ?? 0}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyReadSection() {
    if (_recentlyReadBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildBookSection(
      title: 'Recently Read',
      books: _recentlyReadBooks,
      onViewAll: () {
        // Navigate to recently read books screen
      },
    );
  }

  Widget _buildFavoritesSection() {
    if (_favoriteBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildBookSection(
      title: 'Your Favorites',
      books: _favoriteBooks,
      onViewAll: () {
        // Navigate to favorites screen
      },
    );
  }

  Widget _buildDownloadedSection() {
    if (_downloadedBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildBookSection(
      title: 'Downloaded Books',
      books: _downloadedBooks,
      onViewAll: () {
        // Navigate to downloaded books screen
      },
    );
  }

  Widget _buildBookSection({
    required String title,
    required List<Book> books,
    required VoidCallback onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildBookCard(books[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                // Open BookDetailScreen and refresh stats after pop
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
                _loadData();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverImage != null
                      ? Image.network(
                          book.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.book,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            book.authorNames,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (book.readingProgress != null && book.readingProgress! > 0)
            LinearProgressIndicator(
              value: book.readingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _userService.signOutUser();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 