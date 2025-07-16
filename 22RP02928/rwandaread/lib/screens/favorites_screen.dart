import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final BookService _bookService = BookService();
  List<Book> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await _bookService.initialize();
    setState(() {
      _favorites = _bookService.getFavoriteBooks();
      _isLoading = false;
    });
  }

  Future<void> _refreshFavorites() async {
    setState(() => _isLoading = true);
    await _loadFavorites();
  }

  Future<void> _removeFavorite(Book book) async {
    await _bookService.removeFavorite(book.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFavorites,
              child: _favorites.isEmpty
                  ? const Center(child: Text('No favorite books yet.'))
                  : ListView.builder(
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final book = _favorites[index];
                        return ListTile(
                          leading: book.coverImage != null
                              ? Image.network(book.coverImage!, width: 40, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.book),
                          title: Text(book.title),
                          subtitle: Text(book.authors.join(', ')),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                            );
                            _refreshFavorites();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove from favorites',
                            onPressed: () => _removeFavorite(book),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
} 