import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, String> book;
  final bool isPremiumUser;
  final VoidCallback? onUpgrade;
  const BookDetailScreen({super.key, required this.book, this.isPremiumUser = false, this.onUpgrade});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool trialEnded = false;

  @override
  void initState() {
    super.initState();
    checkTrial();
  }

  Future<void> checkTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateString = prefs.getString('trial_start_date');
    DateTime now = DateTime.now();

    if (startDateString == null) {
      // First time: save the current date
      await prefs.setString('trial_start_date', now.toIso8601String());
      setState(() {
        trialEnded = false;
      });
    } else {
      DateTime startDate = DateTime.parse(startDateString);
      if (now.difference(startDate).inDays >= 7) {
        setState(() {
          trialEnded = true;
        });
      } else {
        setState(() {
          trialEnded = false;
        });
      }
    }
  }

  void showBuyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trial Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your free 7-day trial is over. Please purchase to continue reading new books.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Integrate payment logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment feature coming soon!')),
                );
              },
              child: const Text('Pay Now'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.book['premium'] == 'true';
    // Removed fetchRelatedBooks and showRelatedBooksDialog functions

    Future<String?> fetchBookExcerpt(String workKey) async {
      final url = Uri.parse('https://openlibrary.org$workKey.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['excerpts'] != null && data['excerpts'] is List && data['excerpts'].isNotEmpty) {
          return data['excerpts'][0]['excerpt'];
        }
        if (data['description'] != null) {
          if (data['description'] is String) return data['description'];
          if (data['description'] is Map && data['description']['value'] != null) return data['description']['value'];
        }
      }
      return 'No preview available for this book.';
    }

    void showBookPreviewDialog(BuildContext context, String preview) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Book Preview'),
          content: SingleChildScrollView(child: Text(preview)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    Future<void> openBookPreview(BuildContext context, String title) async {
      final url = Uri.parse('https://openlibrary.org/search?q=${Uri.encodeComponent(title)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the book preview.')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8), // Soft green background
      appBar: AppBar(title: Text(widget.book['title'] ?? 'Book Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 200,
                width: 140,
                color: Colors.grey[200],
                child: widget.book['image'] != null
                  ? Image.asset(widget.book['image']!, fit: BoxFit.cover)
                  : const Icon(Icons.book, size: 60),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.book['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('by ${widget.book['author'] ?? ''}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            if (isPremium)
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Premium Book', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                ],
              ),
            const SizedBox(height: 16),
            const Text('About the author', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('J.D. Salinger was an American writer, best known for his 1951 novel The Catcher in the Rye.'),
            const SizedBox(height: 12),
            const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('The Catcher in the Rye is a novel by J.D. Salinger, partially published in serial form in 1945–1946 and as a novel in 1951.'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (isPremium && !widget.isPremiumUser) {
                        _showUpgradeDialog(context);
                        return;
                      }
                      openBookPreview(context, widget.book['title'] ?? '');
                    },
                    child: const Text('Read Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isPremium && !widget.isPremiumUser) {
                        _showUpgradeDialog(context);
                        return;
                      }
                      if (trialEnded) {
                        showBuyDialog();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enjoy your free trial!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: isPremium && !widget.isPremiumUser
                      ? const Text('Upgrade to Premium')
                      : const Text('Buy for ₣14.05'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text('This book is available for premium users only. To access, please upgrade to premium for ₣14.05.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate payment
              Navigator.pop(context);
              if (widget.onUpgrade != null) widget.onUpgrade!();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment of ₣14.05 successful! You are now a premium user.')),
              );
            },
            child: const Text('Pay ₣14.05'),
          ),
        ],
      ),
    );
  }
} 