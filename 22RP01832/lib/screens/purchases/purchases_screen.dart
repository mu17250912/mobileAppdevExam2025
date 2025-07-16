import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/web_download_helper.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You must be logged in to view your purchases.';
      });
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('buyerId', isEqualTo: user.uid)
          .get();
      _purchases = snapshot.docs.map((doc) => doc.data()).toList();
      // Sort by createdAt descending in Dart
      _purchases.sort((a, b) {
        final aTime = a['createdAt'] is Timestamp
            ? (a['createdAt'] as Timestamp).millisecondsSinceEpoch
            : 0;
        final bTime = b['createdAt'] is Timestamp
            ? (b['createdAt'] as Timestamp).millisecondsSinceEpoch
            : 0;
        return bTime.compareTo(aTime);
      });
      setState(() {
        _isLoading = false;
      });
    } catch (e, st) {
      print('Error fetching purchases: $e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String formatRWF(num amount) => 'RWF ${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchases'),
        centerTitle: true,
        leading: const Icon(Icons.shopping_bag_rounded),
        elevation: 2,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: SpinKitWave(color: Color(0xFF9CE800), size: 32),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading purchases:',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : _purchases.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No purchases yet.',
                      style: TextStyle(fontSize: 20, color: Colors.black54),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchPurchases,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  itemCount: _purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final book = _purchases[index];
                    final createdAt = book['createdAt'] is Timestamp
                        ? (book['createdAt'] as Timestamp).toDate()
                        : null;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Color(0xFF9CE800),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  book['imageUrl'] != null &&
                                      book['imageUrl'].isNotEmpty
                                  ? Image.network(
                                      book['imageUrl'],
                                      width: 70,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 90,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.book,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Price: ${formatRWF(book['price'] ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${book['status'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: (book['status'] == 'sold')
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Purchased: ${DateFormat.yMMMd().add_jm().format(createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  if (book['pdfUrl'] != null &&
                                      book['pdfUrl'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.download),
                                        label: const Text('Download PDF'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final url = book['pdfUrl'];
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Download started...',
                                              ),
                                            ),
                                          );
                                          if (kIsWeb) {
                                            triggerWebDownload(url);
                                          } else {
                                            try {
                                              final tempDir =
                                                  await getApplicationDocumentsDirectory();
                                              final savePath =
                                                  '${tempDir.path}/${url.split('/').last}';
                                              await Dio().download(
                                                url,
                                                savePath,
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Download complete! Opening PDF...',
                                                  ),
                                                ),
                                              );
                                              await OpenFilex.open(savePath);
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Download failed: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
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
      ),
    );
  }
}
 