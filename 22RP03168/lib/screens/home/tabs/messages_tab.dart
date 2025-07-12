import 'package:flutter/material.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  // Mock chat data - replace with Firebase data
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'userName': 'John Doe',
      'lastMessage': 'Is this still available?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'unreadCount': 1,
      'userImage': 'https://via.placeholder.com/50x50',
      'productTitle': 'Nike Air Max 270',
    },
    {
      'id': '2',
      'userName': 'Jane Smith',
      'lastMessage': 'Can you ship to my address?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'unreadCount': 0,
      'userImage': 'https://via.placeholder.com/50x50',
      'productTitle': 'Levi\'s 501 Jeans',
    },
    {
      'id': '3',
      'userName': 'Mike Johnson',
      'lastMessage': 'Thanks for the quick response!',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 0,
      'userImage': 'https://via.placeholder.com/50x50',
      'productTitle': 'Adidas Ultraboost',
    },
  ];

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF3DDAD7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF3DDAD7)),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: _chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start conversations by browsing products',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(chat['userImage']),
                      radius: 25,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['userName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (chat['unreadCount'] > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3DDAD7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat['unreadCount']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          chat['productTitle'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat['lastMessage'],
                                style: TextStyle(
                                  color: chat['unreadCount'] > 0 
                                      ? Colors.black 
                                      : Colors.grey[600],
                                  fontWeight: chat['unreadCount'] > 0 
                                      ? FontWeight.w500 
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(chat['timestamp']),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to chat screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening chat with ${chat['userName']}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 