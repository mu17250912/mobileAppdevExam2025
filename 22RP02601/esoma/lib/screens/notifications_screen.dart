import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifications_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool showUnreadOnly = false;

  Stream<List<Map<String, dynamic>>> borrowedBooksStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('borrowed_books')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'title': doc['title'] ?? 'No Title',
              'fileUrl': doc['fileUrl'] ?? '',
            }).toList());
  }

  Future<void> _openUrl(String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Borrowed Books'),
        actions: [
          IconButton(
            icon: Icon(showUnreadOnly ? Icons.mark_email_unread : Icons.mark_email_read),
            tooltip: showUnreadOnly ? 'Show All' : 'Show Unread Only',
            onPressed: () => setState(() {
              showUnreadOnly = !showUnreadOnly;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await NotificationsManager.markAllAsRead();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: NotificationsManager.stream(unreadOnly: showUnreadOnly),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];
          print('NotificationsScreen: notifications count = ${notifications.length}');
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (notifications.isEmpty)
                const Text('No notifications.')
              else
                ...notifications.map((n) => ListTile(
                      leading: n.imageUrl != null && n.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(n.imageUrl!, width: 40, height: 40, fit: BoxFit.cover),
                            )
                          : Icon(_iconForType(n.type), color: _colorForType(n.type), size: 32),
                      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.message),
                      trailing: n.read
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.mark_email_read, color: Colors.green),
                              tooltip: 'Mark as read',
                              onPressed: () => NotificationsManager.markAsRead(n.id),
                            ),
                      onTap: () => _showDetails(context, n),
                    )),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Borrowed Books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: borrowedBooksStream(),
                builder: (context, bookSnapshot) {
                  if (bookSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final borrowedBooks = bookSnapshot.data ?? [];
                  if (borrowedBooks.isEmpty) {
                    return const Text('No borrowed books.');
                  }
                  return Column(
                    children: borrowedBooks.map((book) => ListTile(
                      leading: const Icon(Icons.book, color: Colors.blue),
                      title: Text(book['title'] ?? 'No title'),
                      trailing: IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _openUrl(book['fileUrl'] ?? ''),
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, NotificationItem n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(_iconForType(n.type), color: _colorForType(n.type)),
            const SizedBox(width: 8),
            Expanded(child: Text(n.title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.imageUrl != null && n.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.network(n.imageUrl!, width: 120, height: 120, fit: BoxFit.cover),
                ),
              Text(n.message),
              if (n.timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Received: ${n.timestamp}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (!n.read)
            TextButton(
              onPressed: () {
                NotificationsManager.markAsRead(n.id);
                Navigator.pop(context);
              },
              child: const Text('Mark as read'),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'borrow':
        return Icons.book;
      case 'info':
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'payment':
        return Colors.purple;
      case 'borrow':
        return Colors.blue;
      case 'info':
      default:
        return Colors.grey;
    }
  }
}
