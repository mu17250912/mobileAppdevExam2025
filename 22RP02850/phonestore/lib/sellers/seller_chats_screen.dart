import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../sellers/seller_home.dart';
import '../sellers/manage_products_screen.dart';
import '../clients/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ensure kPrimaryColor is defined locally for seller UI:
const kPrimaryColor = Color(0xFF6C63FF);

class SellerChatsScreen extends StatelessWidget {
  final String sellerId;
  const SellerChatsScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please login to view chats'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No chats yet.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final productId = data['productId'] ?? '';
            final clientId = data['clientId'] ?? '';
            final lastMessage = data['lastMessage'] ?? '';
            final lastTimestamp = (data['lastTimestamp'] as Timestamp?)?.toDate();
            return ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text('Product: $productId'),
              subtitle: Text(lastMessage),
              trailing: lastTimestamp != null
                  ? Text('${lastTimestamp.hour}:${lastTimestamp.minute.toString().padLeft(2, '0')}')
                  : null,
              onTap: () async {
                final productSnap = await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get();
                if (!productSnap.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product not found.')),
                  );
                  return;
                }
                final product = Product.fromDocument(productSnap);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(),
                    settings: RouteSettings(
                      arguments: {
                        'product': product,
                        'sellerId': sellerId,
                        'clientId': clientId,
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 