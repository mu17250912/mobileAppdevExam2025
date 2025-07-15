import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final TextEditingController _userSearchController = TextEditingController();
  List<UserDetails> _userSearchResults = [];
  List<UserDetails> _allUsers = [];
  bool _isUserSearching = false;
  bool _hasSearched = false; // Track if user has performed a search
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final users = await _firestore.collection('users').get();
      final results = users.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) => UserDetails.fromFirestore(doc))
          .toList();
      setState(() {
        _allUsers = results;
      });
    } catch (e) {
      setState(() {
        _allUsers = [];
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userSearchResults = [];
        _isUserSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isUserSearching = true;
      _hasSearched = true;
    });

    try {
      final users = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      final results = users.docs
          .where((doc) => doc.id != _auth.currentUser?.uid)
          .map((doc) => UserDetails.fromFirestore(doc))
          .toList();

      setState(() {
        _userSearchResults = results;
        _isUserSearching = false;
      });
    } catch (e) {
      setState(() {
        _userSearchResults = [];
        _isUserSearching = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error searching for users. Please try again.'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Determine which users to show: search results or all users
    final List<UserDetails> usersToShow =
        _userSearchController.text.isNotEmpty ? _userSearchResults : _allUsers;

    return Scaffold(
      // Removed AppBar here to avoid duplicate headers
      // appBar: AppBar(
      //   title: const Text('Chats'),
      //   backgroundColor: Colors.blue[800],
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.search),
      //       onPressed: () {
      //         showSearch(
      //           context: context,
      //           delegate: ChatSearchDelegate(),
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          // User search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _userSearchController,
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: _userSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _userSearchController.clear();
                          setState(() {
                            _userSearchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _userSearchResults = [];
                    _hasSearched = false;
                  });
                } else {
                  _searchUsers(value);
                }
              },
            ),
          ),
          if (_isUserSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (usersToShow.isEmpty && !_isUserSearching)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off,
                        size: isTablet ? 80 : 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No users match your search criteria',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (usersToShow.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      _userSearchController.text.isNotEmpty
                          ? 'Search Results (${usersToShow.length})'
                          : 'All Users (${usersToShow.length})',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: usersToShow.length,
                      itemBuilder: (context, index) {
                        final user = usersToShow[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: isTablet ? 30 : 25,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.blue[600],
                              size: isTablet ? 24 : 20,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: user.uid,
                                    receiverName: user.fullName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          // Chat threads list
          Expanded(
            child: StreamBuilder<List<ChatThread>>(
              stream: ChatService.getChatThreadsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Improved error handling
                  final user = _auth.currentUser;
                  if (user == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: isTablet ? 80 : 60, color: Colors.blue),
                          const SizedBox(height: 16),
                          Text(
                            'Please log in to view your chats.',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: isTablet ? 80 : 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load chats. Please try again later.',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final threads = snapshot.data ?? [];
                final filteredThreads = threads; // No search filter

                if (filteredThreads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: isTablet ? 120 : 80, color: Colors.grey),
                        SizedBox(height: isTablet ? 24 : 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No chats yet'
                              : 'No chats found',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Start a conversation with other users'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredThreads.length,
                  itemBuilder: (context, index) {
                    final thread = filteredThreads[index];
                    return _buildChatTile(thread, isTablet);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatThread thread, bool isTablet) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final otherUserId = thread.getOtherUserId(currentUserId);
    final isUnread = thread.unreadCount > 0;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['fullName'] ?? 'Unknown User';
        final userAvatar = userData?['profilePicture'] ?? '';
        print(
            '[DEBUG] ChatList: Fetched user for chat thread: otherUserId=$otherUserId, userName=$userName');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: isUnread ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: isTablet ? 30 : 25,
              backgroundColor: Colors.blue[100],
              backgroundImage:
                  userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
              child: userAvatar.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (thread.isEncrypted)
                  Icon(Icons.lock,
                      size: isTablet ? 20 : 16, color: Colors.green),
                if (thread.mode == ChatMode.detailed)
                  Icon(Icons.description,
                      size: isTablet ? 20 : 16, color: Colors.blue),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  thread.lastMessageText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: isUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(thread.lastMessageTime),
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (thread.lastMessageSenderId == currentUserId)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.done_all,
                          size: isTablet ? 16 : 14,
                          color: isUnread ? Colors.blue : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: isUnread
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${thread.unreadCount > 99 ? '99+' : thread.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              print(
                  '[DEBUG] Navigating to ChatScreen: receiverId=$otherUserId, receiverName=$userName');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverId: otherUserId,
                    receiverName: userName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

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
}

class ChatSearchDelegate extends SearchDelegate<String> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Start typing to search chats...'),
      );
    }

    return StreamBuilder<List<ChatThread>>(
      stream: ChatService.getChatThreadsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final threads = snapshot.data ?? [];
        final filteredThreads = threads.where((thread) {
          return thread.lastMessageText
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();

        if (filteredThreads.isEmpty) {
          return const Center(
            child: Text('No chats found matching your search.'),
          );
        }

        return ListView.builder(
          itemCount: filteredThreads.length,
          itemBuilder: (context, index) {
            final thread = filteredThreads[index];
            final otherUserId =
                thread.getOtherUserId(_auth.currentUser?.uid ?? '');

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherUserId).get(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final userName = userData?['fullName'] ?? 'Unknown User';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  title: Text(userName),
                  subtitle: Text(
                    thread.lastMessageText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: otherUserId,
                          receiverName: userName,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
