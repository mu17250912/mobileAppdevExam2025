import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/review.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<bool> _canReviewFuture;
  final _reviewController = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _logProductView();
    _canReviewFuture = _checkIfUserCanReview();
  }

  Future<void> _logProductView() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'view_product',
      parameters: {
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'price': widget.product.price,
        'seller_id': widget.product.sellerId,
      },
    );
  }

  Future<bool> _checkIfUserCanReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    // Check if user has an order with this product
    final orders = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in orders.docs) {
      final items = List<Map<String, dynamic>>.from(doc['items'] ?? []);
      if (items.any((item) => item['productId'] == widget.product.id)) {
        // Check if user already reviewed
        final reviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('productId', isEqualTo: widget.product.id)
            .where('userId', isEqualTo: user.uid)
            .get();
        if (reviews.docs.isEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final review = Review(
      id: '',
      userId: user.uid,
      userEmail: user.email ?? '',
      userName: user.displayName ?? '',
      productId: widget.product.id,
      rating: _rating,
      comment: _reviewController.text.trim(),
      createdAt: DateTime.now(),
    );
    await FirebaseFirestore.instance.collection('reviews').add(review.toMap());
    setState(() {
      _canReviewFuture = Future.value(false);
    });
    _reviewController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildProductDetails(BuildContext context) {
    final product = widget.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: product.imageUrl.isNotEmpty
                ? Image.network(product.imageUrl, height: 200, fit: BoxFit.cover)
                : Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 8),
        Text('£${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple)),
        const SizedBox(height: 8),
        Text(product.inStock ? 'In stock' : 'Out of stock', style: TextStyle(color: product.inStock ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (product.description.isNotEmpty)
          Text(product.description, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Chat with Seller'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login to chat with the seller.')),
              );
              return;
            }
            // Navigate to chat screen (to be implemented)
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: {
                'product': product,
                'sellerId': product.sellerId,
                'clientId': user.uid,
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('productId', isEqualTo: product.id)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No reviews yet.');
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final review = Review.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
                return ListTile(
                  leading: CircleAvatar(child: Text(review.userName.isNotEmpty ? review.userName[0] : '?')),
                  title: Row(
                    children: [
                      Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        )),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.comment),
                      Text('${review.createdAt.toLocal()}'.split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        FutureBuilder<bool>(
          future: _canReviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }
            if (snapshot.data == true) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add a review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Rating:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _rating,
                        items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                        onChanged: (val) {
                          if (val != null) setState(() => _rating = val);
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(labelText: 'Comment'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitReview,
                    child: const Text('Submit Review'),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only return the product details content, no Scaffold/AppBar
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildProductDetails(context),
      ),
    );
  }
} 