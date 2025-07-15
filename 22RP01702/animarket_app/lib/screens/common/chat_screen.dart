import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  final String sellerPhone;

  const ChatScreen({
    Key? key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For demo: just show seller info and a placeholder for chat
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $sellerName'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text(sellerName),
            subtitle: Text('Phone: $sellerPhone'),
          ),
          Expanded(
            child: Center(child: Text('Chat UI goes here')),
          ),
        ],
      ),
    );
  }
}
