import 'package:flutter/material.dart';
import '../../models/book.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment/payment_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../utils/web_download_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Book _book;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  Future<void> _refreshBook() async {
    setState(() {
      _isLoading = true;
    });
    final doc = await FirebaseFirestore.instance
        .collection('books')
        .doc(_book.id)
        .get();
    if (doc.exists) {
      setState(() {
        _book = Book.fromMap(doc.data()!, doc.id);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchSellerInfo(String sellerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  String formatRWF(num amount) => 'RWF ${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isSeller = user != null && user.uid == _book.sellerId;
    final isBuyer =
        user != null && _book.pdfUrl != null && _book.buyerId == user.uid;
    final isAvailable = _book.status == 'available';
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: _book.imageUrl.isNotEmpty
                          ? Image.network(_book.imageUrl, height: 180)
                          : Container(height: 180, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _book.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Seller info section
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchSellerInfo(_book.sellerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 32,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final seller = snapshot.data;
                        if (seller == null) {
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Seller info unavailable'),
                          );
                        }
                        return ListTile(
                          leading:
                              seller['profileImageUrl'] != null &&
                                  seller['profileImageUrl']
                                      .toString()
                                      .isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    seller['profileImageUrl'],
                                  ),
                                )
                              : CircleAvatar(
                                  child: Text(
                                    (seller['name'] ??
                                            seller['email'] ??
                                            'U')[0]
                                        .toUpperCase(),
                                  ),
                                ),
                          title: Text(seller['name'] ?? 'No Name'),
                          subtitle: Text(seller['email'] ?? ''),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    Text(
                      'Subject: ${_book.subject}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: ${formatRWF(_book.price)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_book.description),
                    const Divider(height: 32),
                    if (!isSeller && isAvailable && !isBuyer)
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PaymentPage(book: _book),
                              ),
                            );
                            if (result == true) {
                              await _refreshBook();
                            }
                          },
                          child: const Text('Buy'),
                        ),
                      ),
                    if (_book.pdfUrl != null && (isSeller || isBuyer))
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download PDF'),
                          onPressed: () async {
                            final url = _book.pdfUrl!;
                            if (kIsWeb) {
                              triggerWebDownload(url);
                            } else {
                              try {
                                final tempDir =
                                    await getApplicationDocumentsDirectory();
                                final savePath =
                                    '${tempDir.path}/${url.split('/').last}';
                                await Dio().download(url, savePath);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Download complete! Opening PDF...',
                                    ),
                                  ),
                                );
                                await OpenFilex.open(savePath);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Download failed: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    if (isSeller)
                      const Center(
                        child: Text('You are the seller of this book.'),
                      ),
                    if (!isAvailable && !isBuyer && !isSeller)
                      const Center(
                        child: Text('This book is no longer available.'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
 