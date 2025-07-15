import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _retryKey = 0;

  void _retry() {
    setState(() {
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      key: ValueKey(_retryKey),
      stream: AuthService().user,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return Center(child: CircularProgressIndicator());
        final user = userSnap.data!;
        final notificationStream = FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots()
            .timeout(const Duration(seconds: 5));
        return StreamBuilder<QuerySnapshot>(
          key: ValueKey(_retryKey),
          stream: notificationStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFF22A6F2),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF22A6F2),
                  elevation: 0,
                  title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  centerTitle: true,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snap.error is TimeoutException
                          ? 'Loading is taking too long. Please check your connection or try again.'
                          : 'Failed to load notifications. Please try again.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _retry,
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF22A6F2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Scaffold(
                backgroundColor: const Color(0xFF22A6F2),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF22A6F2),
                  elevation: 0,
                  title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  centerTitle: true,
                ),
                body: Center(child: Text('No notifications yet!', style: TextStyle(color: Colors.white, fontSize: 18))),
              );
            }
            return Scaffold(
              backgroundColor: const Color(0xFF22A6F2),
              appBar: AppBar(
                backgroundColor: const Color(0xFF22A6F2),
                elevation: 0,
                title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: const Color(0xFF22A6F2)),
                      title: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['body'] ?? ''),
                      trailing: data['read'] == true ? null : Icon(Icons.fiber_new, color: Colors.red),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
} 