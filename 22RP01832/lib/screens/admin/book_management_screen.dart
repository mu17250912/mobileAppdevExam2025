import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'admin_dashboard.dart';
import 'user_management_screen.dart';
import 'finance_screen.dart';
import 'reports_screen.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({Key? key}) : super(key: key);

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Management'),
        backgroundColor: Colors.black,
      ),
      drawer: _adminDrawer(context),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, subject, or seller',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitWave(color: Color(0xFF9CE800), size: 32),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No books found.'));
                }
                final books = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final subject = (data['subject'] ?? '')
                      .toString()
                      .toLowerCase();
                  final seller = (data['sellerId'] ?? '')
                      .toString()
                      .toLowerCase();
                  return title.contains(_search.toLowerCase()) ||
                      subject.contains(_search.toLowerCase()) ||
                      seller.contains(_search.toLowerCase());
                }).toList();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = books[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isAvailable = data['status'] == 'available';
                    return Card(
                      elevation: 4,
                      color: Colors.white,
                      shadowColor: Colors.deepPurple.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading:
                            data['imageUrl'] != null &&
                                data['imageUrl'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const CircleAvatar(child: Icon(Icons.book)),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subject: ${data['subject'] ?? ''}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            Text(
                              'Status: ${data['status'] ?? 'unknown'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              'Seller: ${data['sellerId'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isAvailable ? Icons.block : Icons.check_circle,
                                color: isAvailable ? Colors.red : Colors.green,
                              ),
                              tooltip: isAvailable
                                  ? 'Mark as Unavailable'
                                  : 'Mark as Available',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      isAvailable
                                          ? 'Mark as Unavailable'
                                          : 'Mark as Available',
                                    ),
                                    content: Text(
                                      'Are you sure you want to ${isAvailable ? 'mark this book as unavailable' : 'mark this book as available'}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF9CE800),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          isAvailable
                                              ? 'Mark Unavailable'
                                              : 'Mark Available',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.update({
                                    'status': isAvailable
                                        ? 'unavailable'
                                        : 'available',
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.deepPurple,
                              ),
                              tooltip: 'Edit Book',
                              onPressed: () {
                                // TODO: Implement edit book details
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BookSwap',
                  style: TextStyle(
                    color: Color(0xFF9CE800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.black),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.blue),
            title: const Text('User Management'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.deepPurple),
            title: const Text('Book Management'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BookManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text('Finance'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const FinanceScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFF9CE800)),
            title: const Text('Reports'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
