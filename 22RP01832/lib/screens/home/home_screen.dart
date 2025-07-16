import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/book_provider.dart';
import '../../models/book.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'book_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
    });
    await provider.Provider.of<BookProvider>(
      context,
      listen: false,
    ).fetchBooks();
    if (mounted)
      setState(() {
        _isLoading = false;
      });
  }

  String formatRWF(num amount) => 'RWF ${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final bookProvider = provider.Provider.of<BookProvider>(context);
    final List<Book> books = _searchQuery.isEmpty
        ? bookProvider.books.where((b) => b.status == 'available').toList()
        : bookProvider
              .searchBooks(_searchQuery)
              .where((b) => b.status == 'available')
              .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by title, subject, or price',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF9CE800), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SpinKitWave(color: Color(0xFF9CE800), size: 32),
                    )
                  : books.isEmpty
                  ? const Center(child: Text('No books found.'))
                  : RefreshIndicator(
                      onRefresh: _fetchBooks,
                      child: ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.white,
                            elevation: 6,
                            shadowColor: Color(0xFF9CE800),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: book.imageUrl.isNotEmpty
                                  ? Image.network(
                                      book.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                    ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Subject: ${book.subject}\nPrice: ${formatRWF(book.price)}',
                              ),
                              isThreeLine: true,
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookDetailsScreen(book: book),
                                    ),
                                  );
                                  // Reload books after returning from details
                                  await provider.Provider.of<BookProvider>(
                                    context,
                                    listen: false,
                                  ).fetchBooks();
                                  setState(() {});
                                },
                                child: const Text('View'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
