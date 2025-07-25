import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'book_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final BookService _bookService = BookService();
  List<String> _categories = [];
  Map<String, List<Book>> _booksByCategory = {};
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await _bookService.initialize();
    final books = _bookService.getAllBooks();
    final Set<String> categories = {};
    final Map<String, List<Book>> booksByCat = {};
    for (final book in books) {
      for (final cat in book.categories) {
        categories.add(cat);
        booksByCat.putIfAbsent(cat, () => []).add(book);
      }
    }
    setState(() {
      _categories = ['All', ...categories.toList()..sort()];
      _booksByCategory = booksByCat;
      _booksByCategory['All'] = books;
      _isLoading = false;
    });
  }

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCategories,
              child: _selectedCategory == null
                  ? ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Container(
                          color: category == 'All' ? Colors.grey[300] : null,
                          child: ListTile(
                            title: Text(category),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => setState(() => _selectedCategory = category),
                          ),
                        );
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.arrow_back),
                          title: Text(_selectedCategory!),
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _booksByCategory[_selectedCategory]?.length ?? 0,
                            itemBuilder: (context, index) {
                              final book = _booksByCategory[_selectedCategory]![index];
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
                                  _refreshCategories();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
} 