import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../sellers/seller_home.dart';
import '../sellers/manage_products_screen.dart';
import '../clients/chat_screen.dart';

// Ensure kPrimaryColor is defined locally for seller UI:
const kPrimaryColor = Color(0xFF6C63FF);

class SellerChatsScreen extends StatelessWidget {
  final String sellerId;
  const SellerChatsScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats with Clients')),
      body: StreamBuilder<QuerySnapshot>(
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
                  // Fetch product details for chat screen
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SellerHomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
            );
          } else if (index == 2) {
            // Already on chats
          }
        },
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
    );
  }
} 