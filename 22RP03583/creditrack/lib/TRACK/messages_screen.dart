import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No messages'));
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(data['text'] ?? ''),
                    subtitle: data['timestamp'] != null
                        ? Text(DateTime.fromMillisecondsSinceEpoch((data['timestamp'] as Timestamp).millisecondsSinceEpoch).toString())
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        final newText = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController(text: data['text']);
                            return AlertDialog(
                              title: Text('Edit Message'),
                              content: TextField(
                                controller: controller,
                                decoration: InputDecoration(labelText: 'Message'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, controller.text),
                                  child: Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                        if (newText != null && newText.trim().isNotEmpty && newText != data['text']) {
                          await doc.reference.update({'text': newText});
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newText = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: Text('New Message'),
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Message'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
          if (newText != null && newText.trim().isNotEmpty) {
            await FirebaseFirestore.instance.collection('messages').add({
              'text': newText,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Add Message',
      ),
    );
  }
} 