import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No notifications', style: TextStyle(color: Colors.white)));
                  }
                  final notifications = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final data = notif.data() as Map<String, dynamic>;
                      final isRead = data['read'] ?? false;
                      return Card(
                        color: isRead ? Colors.white : Colors.yellow[100],
                        child: ListTile(
                          title: Text(data['title'] ?? '', style: TextStyle(color: Color(0xFF7B8AFF))),
                          subtitle: Text(data['body'] ?? ''),
                          trailing: isRead ? null : Icon(Icons.fiber_new, color: Colors.red),
                          onTap: () {
                            notif.reference.update({'read': true});
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF7B8AFF),
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: () async {
                  final notifications = FirebaseFirestore.instance.collection('notifications');
                  await notifications.add({
                    'userId': user.uid,
                    'title': 'Test Notification',
                    'body': 'This is a test notification.',
                    'category': 'General',
                    'timestamp': DateTime.now(),
                    'read': false,
                  });
                },
                child: Text('Add Test Notification'),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF7B8AFF),
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: () async {
                  final batch = FirebaseFirestore.instance.batch();
                  final snap = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: user.uid)
                      .get();
                  for (var doc in snap.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                },
                child: Text('Clear all notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 