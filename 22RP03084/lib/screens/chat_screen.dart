import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart'; // for kGoldenBrown
import 'app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment/hdev_payment.dart';
import '../utils/payment_utils.dart';
// SubscriptionScreen is also defined in register_screen.dart

// Local helper to show payment plans dialog
// Minimal SubscriptionScreen widget for payment plans dialog fallback
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
  });
}

final List<SubscriptionPlan> kPlans = [
  SubscriptionPlan(id: 'weekly', name: 'Weekly', description: 'Unlimited messages for 1 week', price: 0.2, currency: 'RWF'),
  SubscriptionPlan(id: 'monthly', name: 'Monthly', description: 'Unlimited messages for 1 month', price: 10, currency: 'RWF'),
  SubscriptionPlan(id: 'annual', name: 'Annual', description: 'Unlimited messages for 1 year', price: 35, currency: 'RWF'),
];

class SubscriptionScreen extends StatelessWidget {
  final void Function(SubscriptionPlan plan)? onPlanSelected;
  const SubscriptionScreen({Key? key, this.onPlanSelected}) : super(key: key);

  Future<void> _payWithMoMo(BuildContext context, SubscriptionPlan plan) async {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay for ${plan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your MoMo phone number to pay ${(plan.price * 1200).toInt()} RWF'),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;
              Navigator.of(ctx).pop();
              final amountRwf = (plan.price * 1200).toInt();
              final transactionRef = 'TX-${DateTime.now().millisecondsSinceEpoch}';
              final hdev = HdevPayment(apiId: 'HDEV-2f7b3554-eb27-477b-8ebb-2ca799f03412-ID', apiKey: 'HDEV-28407ece-5d24-438d-a9e8-73105c905a7d-KEY');
              final payResp = await hdev.pay(tel: phone, amount: amountRwf.toString(), transactionRef: transactionRef);
              if (payResp != null && payResp['status'] == 'success') {
                // Poll for payment status
                bool paid = false;
                for (int i = 0; i < 10; i++) {
                  await Future.delayed(Duration(seconds: 3));
                  final statusResp = await hdev.getPay(transactionRef: transactionRef);
                  if (statusResp != null && statusResp['status'] == 'success') {
                    paid = true;
                    break;
                  }
                }
                if (paid) {
                  // Activate plan in Firestore
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'subscriptionStatus': 'active',
                      'subscriptionPlan': plan.id,
                      'subscriptionActivatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  }
                  if (onPlanSelected != null) onPlanSelected!(plan);
                  Navigator.of(context).pop(plan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment successful! Plan activated.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment not confirmed. Try again.')),
                  );
                }
              } else {
                showPaymentError(context, payResp != null ? payResp['message'] : null);
              }
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.amber[700];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: accent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: kPlans.length,
        itemBuilder: (context, i) {
          final plan = kPlans[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 18),
            elevation: 4,
            child: ListTile(
              title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              subtitle: Text(plan.description),
              trailing: Text(
                '${(plan.price * 1200).toStringAsFixed(0)} RWF',
                style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              onTap: () => _payWithMoMo(context, plan),
            ),
          );
        },
      ),
    );
  }
}
Future<dynamic> showPaymentPlansDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: SizedBox(
        height: 400,
        child: SubscriptionScreen(),
      ),
    ),
  );
}

class ChatScreen extends StatefulWidget {
  final String userId; // This should be Firebase UID
  final bool isEmployer;
  const ChatScreen({Key? key, required this.userId, this.isEmployer = false}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? widget.userId;
  String? _selectedChatUserId;
  String? _selectedChatUserName;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _allUsers = [];
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    if (widget.isEmployer) _listenForUnread();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUsers = users.docs
        .where((doc) => doc.id != currentUid)
        .where((doc) {
          final data = doc.data();
          if ((data['userType'] ?? '') == 'employer') return true;
          if (widget.isEmployer) return (data['userType'] ?? '') == 'job_seeker';
          return false;
        })
        .map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'name': data['companyName'] ?? data['name'] ?? doc.id,
            'photo': data['profileImageUrl'],
            'userType': data['userType'] ?? '',
          };
        }).toList();
    });
  }

  void _showNewChatDialog() async {
    await _fetchAllUsers();
    showDialog(
      context: context,
      builder: (ctx) {
        List<Map<String, dynamic>> filtered = _allUsers.where((u) =>
          u['name'].toString().toLowerCase().contains(_userSearch.toLowerCase())
        ).toList();
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Start New Chat'),
            content: SizedBox(
              width: 350,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search users',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setStateDialog(() => _userSearch = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                      ? const Center(child: Text('No users found.'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final user = filtered[i];
                            return ListTile(
                              leading: user['photo'] != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user['photo']))
                                : const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(user['name']),
                              subtitle: Text(user['userType']),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                setState(() {
                                  _selectedChatUserId = user['uid'];
                                  _selectedChatUserName = user['name'];
                                });
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _listenForUnread() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .listen((snapshot) async {
      int count = 0;
      for (final doc in snapshot.docs) {
        final messages = await doc.reference.collection('messages')
            .where('receiver', isEqualTo: currentUid)
            .where('read', isEqualTo: false)
            .get();
        count += messages.docs.length;
      }
      setState(() { _unreadCount = count; });
    });
  }

  void _showNotifications(BuildContext context) async {
    final chats = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .get();
    final unreadChats = <Map<String, dynamic>>[];
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('messages')
          .where('receiver', isEqualTo: currentUid)
          .where('read', isEqualTo: false)
          .get();
      if (messages.docs.isNotEmpty) {
        final participants = List<String>.from(chat['participants']);
        final otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => '');
        // Lookup user by UID
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
        String userName = otherUid;
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          userName = data['companyName'] ?? data['name'] ?? otherUid;
        }
        unreadChats.add({
          'userId': otherUid,
          'userName': userName,
        });
      }
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unread Messages'),
        content: unreadChats.isEmpty
            ? const Text('No unread messages.')
            : SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unreadChats.length,
                  itemBuilder: (context, i) {
                    final chat = unreadChats[i];
                    return ListTile(
                      title: Text(chat['userName']),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedChatUserId = chat['userId'];
                          _selectedChatUserName = chat['userName'];
                        });
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatUserId == null) {
      // Show list of conversations
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: kGoldenBrown,
          actions: [
            if (widget.isEmployer)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: kGoldenBrown),
                    onPressed: () => _showNotifications(context),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        drawer: AppDrawer(userId: currentUid, isEmployer: widget.isEmployer),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
            }
            final chats = snapshot.data!.docs;
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEmployer
                        ? 'No one has messaged you yet.'
                        : 'No conversations yet.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    if (widget.isEmployer) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_comment, color: Colors.white),
                        style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown, foregroundColor: Colors.white),
                        label: const Text('Start Chat with Job Seeker', style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          // Show dialog to pick a job seeker and start chat
                          final jobSeekers = await FirebaseFirestore.instance
                              .collection('users')
                              .where('userType', isEqualTo: 'job_seeker')
                              .get();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Job Seeker'),
                              content: SizedBox(
                                width: 300,
                                height: 400,
                                child: jobSeekers.docs.isEmpty
                                    ? const Center(child: Text('No job seekers found.'))
                                    : ListView.builder(
                                        itemCount: jobSeekers.docs.length,
                                        itemBuilder: (context, i) {
                                          final user = jobSeekers.docs[i];
                                          final name = user.data().containsKey('companyName')
                                              ? user['companyName']
                                              : (user.data().containsKey('name') ? user['name'] : user.id);
                                          final photo = user.data().containsKey('profileImageUrl') ? user['profileImageUrl'] : null;
                                          final jobSeekerUid = user.id;
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: photo != null ? NetworkImage(photo) : null,
                                              child: photo == null ? const Icon(Icons.person) : null,
                                            ),
                                            title: Text(name),
                                            subtitle: Text(name),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              setState(() {
                                                _selectedChatUserId = jobSeekerUid;
                                                _selectedChatUserName = name;
                                              });
                                            },
                                          );
                                        },
                                      ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final participants = List<String>.from(chat['participants']);
                final otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => '');
                final lastTimestamp = chat['lastTimestamp'] as Timestamp?;
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                  builder: (context, userSnap) {
                    String userName = otherUid;
                    String? userPhoto;
                    if (userSnap.hasData && userSnap.data != null && userSnap.data!.data() != null) {
                      final data = userSnap.data!.data() as Map<String, dynamic>;
                      userName = data['companyName'] ?? data['name'] ?? otherUid;
                      userPhoto = data.containsKey('profileImageUrl') ? data['profileImageUrl'] : null;
                    }
                    return StreamBuilder<QuerySnapshot>(
                      stream: chat.reference.collection('messages')
                        .where('receiver', isEqualTo: currentUid)
                        .where('read', isEqualTo: false)
                        .snapshots(),
                      builder: (context, unreadSnap) {
                        final unreadCount = unreadSnap.data?.docs.length ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
                            child: userPhoto == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(userName),
                          subtitle: Text(userName),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (lastTimestamp != null)
                                Text(
                                  _formatTimestamp(lastTimestamp),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedChatUserId = otherUid;
                              _selectedChatUserName = userName;
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewChatDialog,
          backgroundColor: kGoldenBrown,
          child: const Icon(Icons.add_comment, color: Colors.white),
          tooltip: 'Start New Chat',
        ),
      );
    } else {
      // Show chat thread
      return ChatThreadScreen(
        currentUserId: currentUid,
        otherUserId: _selectedChatUserId!,
        otherUserName: _selectedChatUserName ?? _selectedChatUserId!,
        onBack: () => setState(() => _selectedChatUserId = null),
      );
    }
  }
}

String _formatTimestamp(Timestamp timestamp) {
  final dt = timestamp.toDate();
  final now = DateTime.now();
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class ChatThreadScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final VoidCallback onBack;
  const ChatThreadScreen({Key? key, required this.currentUserId, required this.otherUserId, required this.otherUserName, required this.onBack}) : super(key: key);

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  void _showSubscriptionDialog() async {
    final selectedPlan = await showPaymentPlansDialog(context);
    if (selectedPlan != null) {
      // Navigate to payment flow with selectedPlan
      Navigator.of(context).pushNamed('/subscription', arguments: selectedPlan);
    }
  }
  bool _canSendMessage = true;
  bool _isSubscribed = false;
  int _messagesSentToday = 0;
  DateTime? _lastMessageDate;
  final TextEditingController _msgController = TextEditingController();
  // Always use UIDs for chatId
  String get chatId => widget.currentUserId.compareTo(widget.otherUserId) < 0
      ? '${widget.currentUserId}_${widget.otherUserId}'
      : '${widget.otherUserId}_${widget.currentUserId}';

  @override
  void initState() {
    super.initState();
    // Debug print to help diagnose chatId mismatches
    // Remove or comment out in production
    // ignore: avoid_print
    print('[DEBUG] Opening chat: chatId=$chatId, currentUserId=${widget.currentUserId}, otherUserId=${widget.otherUserId}');
    _markMessagesAsRead();
    _checkSubscriptionAndLimit().then((_) {
      if (!_isSubscribed && _messagesSentToday >= 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSubscriptionDialog();
        });
      }
    });
  }

  Future<void> _checkSubscriptionAndLimit() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      _isSubscribed = (data['subscriptionStatus'] ?? '') == 'active';
      final today = DateTime.now();
      final lastDate = data['lastMessageDate'] != null ? (data['lastMessageDate'] as Timestamp).toDate() : null;
      _lastMessageDate = lastDate;
      _messagesSentToday = data['messagesSentToday'] ?? 0;
      if (!_isSubscribed) {
        if (lastDate == null || lastDate.year != today.year || lastDate.month != today.month || lastDate.day != today.day) {
          // Reset count for new day
          _messagesSentToday = 0;
        }
        setState(() {
          _canSendMessage = _messagesSentToday < 3;
        });
      } else {
        setState(() {
          _canSendMessage = true;
        });
      }
    }
  }

  void _markMessagesAsRead() async {
    final unread = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiver', isEqualTo: widget.currentUserId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      doc.reference.update({'read': true});
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    await _checkSubscriptionAndLimit();
    if (!_canSendMessage) {
      _showSubscriptionDialog();
      return;
    }
    _msgController.clear();
    final msg = {
      'sender': widget.currentUserId,
      'receiver': widget.otherUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };
    // Ensure chat doc exists
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [widget.currentUserId, widget.otherUserId],
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Add message
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(msg);
    // Update user message count
    if (!_isSubscribed) {
      final today = DateTime.now();
      await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).set({
        'messagesSentToday': _messagesSentToday + 1,
        'lastMessageDate': Timestamp.fromDate(today),
      }, SetOptions(merge: true));
      setState(() {
        _messagesSentToday++;
        _canSendMessage = _messagesSentToday < 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.otherUserName),
        backgroundColor: kGoldenBrown,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Chat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: const Text('Are you sure you want to delete this chat and all its messages?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                // Delete all messages
                final messages = await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').get();
                for (final doc in messages.docs) {
                  await doc.reference.delete();
                }
                // Delete chat document
                await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted')));
                  widget.onBack();
                }
              }
            },
          ),
        ],
      ),
      drawer: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get(),
        builder: (context, snapshot) {
          String userName = '';
          String? userPhoto;
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userName = data['companyName'] ?? data['name'] ?? '';
            userPhoto = data['profileImageUrl'] as String?;
          }
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: kGoldenBrown),
                  accountName: Text(userName, style: TextStyle(color: Colors.white, fontSize: 18)),
                  accountEmail: null,
                  currentAccountPicture: userPhoto != null
                      ? CircleAvatar(backgroundImage: NetworkImage(userPhoto))
                      : CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
                ),
                ListTile(
                  leading: Icon(Icons.subscriptions, color: kGoldenBrown),
                  title: Text('Subscription'),
                  subtitle: _isSubscribed && _lastMessageDate != null
                      ? Text('Active until: ' + _lastMessageDate!.add(Duration(days: 30)).toLocal().toString().split(' ')[0], style: TextStyle(color: Colors.green))
                      : null,
                  onTap: () async {
                    final selectedPlan = await showPaymentPlansDialog(context);
                    if (selectedPlan != null) {
                      Navigator.of(context).pushNamed('/subscription', arguments: selectedPlan);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender'] == widget.currentUserId;
                    final text = msg['text'] ?? '';
                    final timestamp = msg['timestamp'] is Timestamp ? (msg['timestamp'] as Timestamp).toDate() : null;
                    final msgId = msg.id;
                    Widget messageWidget = Container(
                      margin: EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: isMe ? 60 : 8,
                        right: isMe ? 8 : 60,
                      ),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isMe ? Color(0xFF075E54) : Color(0xFF262D31),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 16),
                              ),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                              child: Text(
                                '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                    if (isMe) {
                      return Dismissible(
                        key: Key(msgId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .collection('messages')
                            .doc(msgId)
                            .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message deleted')),
                          );
                        },
                        child: messageWidget,
                      );
                    } else {
                      return messageWidget;
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: kGoldenBrown),
                  onPressed: _canSendMessage ? _sendMessage : null,
                ),
              ],
            ),
          ),
          if (!_isSubscribed)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Free users can send 3 messages per day. Subscribe for unlimited messages.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${3 - _messagesSentToday}/3 free messages left today',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 