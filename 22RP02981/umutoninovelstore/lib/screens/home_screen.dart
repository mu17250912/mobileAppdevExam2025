import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'book_detail_screen.dart';
import 'admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../providers/theme_provider.dart';
import 'favorites_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = const [
    'Novel', 'Self-love', 'Science', 'Romance', 'Crime'
  ];

  final List<Map<String, String>> books = const [
    {
      'title': 'Catcher in the Rye',
      'author': 'J.D. Salinger',
      'image': 'assets/images/catcher.jpg',
      'category': 'Novel',
      'premium': 'false',
    },
    {
      'title': 'Someone Like You',
      'author': 'Roald Dahl',
      'image': 'assets/images/someone.jpg',
      'category': 'Self-love',
      'premium': 'false',
    },
    {
      'title': 'Lord of the Rings',
      'author': 'J.R.R Tolkien',
      'image': 'assets/images/lord.jpg',
      'category': 'Science',
      'premium': 'true',
    },
    // New Romance books
    {
      'title': 'Romantic Escape',
      'author': 'Jane Austen',
      'image': 'assets/images/romance.jpg',
      'category': 'Romance',
      'premium': 'false',
    },
    {
      'title': 'Bring Me Back',
      'author': 'B.A. Paris',
      'image': 'assets/images/bringmeback.jpg',
      'category': 'Romance',
      'premium': 'true',
    },
    // New Crime book
    {
      'title': 'Crime and Punishment',
      'author': 'Fyodor Dostoevsky',
      'image': 'assets/images/crime.jpg',
      'category': 'Crime',
      'premium': 'false',
    },
  ];

  final FirebaseService _firebaseService = FirebaseService();
  Set<String> favoriteBookTitles = {};
  bool isLoadingFavorites = true;
  bool isPremiumUser = false;
  int unreadNotificationCount = 0;

  // Search state
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, String>> filteredBooks = [];
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _loadFavorites();
    _loadNotificationCount();
    filteredBooks = books;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      isSearching = false;
      searchController.clear();
      filteredBooks = books;
    });
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBooks = books.where((book) {
        final title = book['title']?.toLowerCase() ?? '';
        final author = book['author']?.toLowerCase() ?? '';
        return title.contains(query) || author.contains(query);
      }).toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'All') {
        filteredBooks = books;
      } else {
        filteredBooks = books.where((book) => (book['category'] ?? '') == category).toList();
      }
      // Also apply search filter if searching
      if (isSearching && searchController.text.isNotEmpty) {
        final query = searchController.text.toLowerCase();
        filteredBooks = filteredBooks.where((book) {
          final title = book['title']?.toLowerCase() ?? '';
          final author = book['author']?.toLowerCase() ?? '';
          return title.contains(query) || author.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoadingFavorites = false;
      });
      return;
    }
    try {
      final favorites = await _firebaseService.getUserFavorites(user.uid);
      setState(() {
        favoriteBookTitles = favorites.map((b) => b['title'] as String).toSet();
        isLoadingFavorites = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFavorites = false;
      });
      // Optionally show an error message
    }
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremiumUser = prefs.getBool('isPremiumUser') ?? false;
    });
  }

  Future<void> _loadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final count = await _firebaseService.getUnreadNotificationCount(user.uid);
      setState(() {
        unreadNotificationCount = count;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _savePremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremiumUser', value);
  }

  Future<void> _toggleFavorite(Map<String, String> book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final bookTitle = book['title']!;
    setState(() {
      if (favoriteBookTitles.contains(bookTitle)) {
        favoriteBookTitles.remove(bookTitle);
      } else {
        favoriteBookTitles.add(bookTitle);
      }
    });
    if (favoriteBookTitles.contains(bookTitle)) {
      await _firebaseService.addToFavorites(user.uid, book);
    } else {
      await _firebaseService.removeFromFavorites(user.uid, book);
    }
  }

  void _upgradeToPremium() {
    setState(() {
      isPremiumUser = true;
    });
    _savePremiumStatus(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are now a Premium user!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'Reader';
    final photoUrl = user?.photoURL;
    String firstLetter = '?';
    final displayName = user?.displayName;
    final email = user?.email;
    if (displayName != null && displayName.isNotEmpty) {
      firstLetter = displayName[0].toUpperCase();
    } else if (email != null && email.isNotEmpty) {
      firstLetter = email[0].toUpperCase();
    }
    return Scaffold(
      backgroundColor: Color(0xFF1B5E20), // Dark green background for home
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => _onSearchChanged(),
              )
            : const Text('What do you want to read today?'),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
          IconButton(
            icon: const Icon(Icons.search),
              onPressed: _startSearch,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                  // Refresh notification count when returning from notification screen
                  _loadNotificationCount();
                },
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      firstLetter,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
              backgroundColor: Colors.blueGrey,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // Admin button (you can remove this in production)
          // IconButton(
          //   icon: const Icon(Icons.admin_panel_settings),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const AdminScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Welcome back, $name!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == 'All',
                    onSelected: (_) => _filterByCategory('All'),
                  ),
                ),
                ...categories.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (_) => _filterByCategory(cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoadingFavorites
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                final book = filteredBooks[index];
                final isFavorite = favoriteBookTitles.contains(book['title']);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book, isPremiumUser: isPremiumUser, onUpgrade: _upgradeToPremium),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: book['image'] != null
                              ? Image.asset(book['image']!, fit: BoxFit.cover)
                              : const Icon(Icons.book, size: 60),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(Map<String, String>.from(book)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(book['author'] ?? '', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          }
        },
      ),
    );
  }
} 