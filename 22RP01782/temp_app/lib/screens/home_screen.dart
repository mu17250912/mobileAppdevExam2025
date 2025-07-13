import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ad_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Gigs Home'),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      // Fetch notifications from Firestore
                      final notifSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('notifications')
                          .orderBy('timestamp', descending: true)
                          .get();
                      List<Map<String, dynamic>> notifications = notifSnap.docs.map((doc) => doc.data()).toList();
                      // Mark all as read
                      for (final doc in notifSnap.docs) {
                        if (doc.data()['read'] == false) {
                          await doc.reference.update({'read': true});
                        }
                      }
                      await showDialog(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('Notifications'),
                              content: SizedBox(
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    notifications.isEmpty
                                        ? const Text('No notifications.')
                                        : Expanded(
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: notifications.map((n) => ListTile(
                                                title: Text(n['title'] ?? 'Notification'),
                                                subtitle: Text(n['body'] ?? ''),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (n['timestamp'] != null)
                                                      Text((n['timestamp'] as Timestamp).toDate().toString().split('.').first),
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () async {
                                                        // Find the notification doc to edit
                                                        QueryDocumentSnapshot<Map<String, dynamic>>? notifDoc;
                                                        try {
                                                          notifDoc = notifSnap.docs.firstWhere((doc) => doc.data()['title'] == n['title'] && doc.data()['body'] == n['body'] && doc.data()['timestamp'] == n['timestamp']);
                                                        } catch (e) {
                                                          notifDoc = null;
                                                        }
                                                        if (notifDoc != null) {
                                                          final titleController = TextEditingController(text: n['title']);
                                                          final bodyController = TextEditingController(text: n['body']);
                                                          final result = await showDialog<bool>(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              title: const Text('Edit Notification'),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  TextField(
                                                                    controller: titleController,
                                                                    decoration: const InputDecoration(labelText: 'Title'),
                                                                  ),
                                                                  TextField(
                                                                    controller: bodyController,
                                                                    decoration: const InputDecoration(labelText: 'Body'),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.pop(context, true),
                                                                  child: const Text('Save'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (result == true && titleController.text.trim().isNotEmpty) {
                                                            await FirebaseFirestore.instance
                                                                .collection('users')
                                                                .doc(user.uid)
                                                                .collection('notifications')
                                                                .doc(notifDoc.id)
                                                                .update({
                                                              'title': titleController.text.trim(),
                                                              'body': bodyController.text.trim(),
                                                            });
                                                            // Refresh notifications
                                                            final notifSnap2 = await FirebaseFirestore.instance
                                                                .collection('users')
                                                                .doc(user.uid)
                                                                .collection('notifications')
                                                                .orderBy('timestamp', descending: true)
                                                                .get();
                                                            setState(() {
                                                              notifications = notifSnap2.docs.map((doc) => doc.data()).toList();
                                                            });
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () async {
                                                        // Find the notification doc to delete
                                                        QueryDocumentSnapshot<Map<String, dynamic>>? notifDoc;
                                                        try {
                                                          notifDoc = notifSnap.docs.firstWhere((doc) => doc.data()['title'] == n['title'] && doc.data()['body'] == n['body'] && doc.data()['timestamp'] == n['timestamp']);
                                                        } catch (e) {
                                                          notifDoc = null;
                                                        }
                                                        if (notifDoc != null) {
                                                          await FirebaseFirestore.instance
                                                              .collection('users')
                                                              .doc(user.uid)
                                                              .collection('notifications')
                                                              .doc(notifDoc.id)
                                                              .delete();
                                                          // Refresh notifications
                                                          final notifSnap2 = await FirebaseFirestore.instance
                                                              .collection('users')
                                                              .doc(user.uid)
                                                              .collection('notifications')
                                                              .orderBy('timestamp', descending: true)
                                                              .get();
                                                          setState(() {
                                                            notifications = notifSnap2.docs.map((doc) => doc.data()).toList();
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              )).toList(),
                                            ),
                                          ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Notification'),
                                      onPressed: () async {
                                        final titleController = TextEditingController();
                                        final bodyController = TextEditingController();
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Add Notification'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: titleController,
                                                  decoration: const InputDecoration(labelText: 'Title'),
                                                ),
                                                TextField(
                                                  controller: bodyController,
                                                  decoration: const InputDecoration(labelText: 'Body'),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (result == true && titleController.text.trim().isNotEmpty) {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('notifications')
                                              .add({
                                            'title': titleController.text.trim(),
                                            'body': bodyController.text.trim(),
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                          // Refresh notifications
                                          final notifSnap2 = await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('notifications')
                                              .orderBy('timestamp', descending: true)
                                              .get();
                                          setState(() {
                                            notifications = notifSnap2.docs.map((doc) => doc.data()).toList();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/signin');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh by rebuilding the widget
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  final isPremium = snapshot.data?.data()?['premium'] ?? false;
                  if (!isPremium) return const SizedBox.shrink();
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('applications')
                        .where('status', isEqualTo: 'completed')
                        .snapshots(),
                    builder: (context, gigsSnap) {
                      final now = DateTime.now();
                      final month = DateFormat('yyyy-MM').format(now);
                      double monthIncome = 0;
                      int gigsCompleted = 0;
                      if (gigsSnap.hasData) {
                        for (final doc in gigsSnap.data!.docs) {
                          final data = doc.data();
                          final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
                          if (completedAt != null && DateFormat('yyyy-MM').format(completedAt) == month) {
                            monthIncome += (data['amount'] ?? 0).toDouble();
                            gigsCompleted++;
                          }
                        }
                      }
                      return Card(
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.bar_chart, color: Colors.deepPurple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This Month\'s Income: \$${monthIncome.toStringAsFixed(2)}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('Gigs Completed: $gigsCompleted'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${user?.email ?? 'User'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.work),
                label: const Text('View Job Listings'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/jobs');
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.dashboard),
                label: const Text('Income Dashboard'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/income');
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Profile'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Premium Features'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/premium');
                },
              ),
              const SizedBox(height: 24),
              const AdBanner(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
