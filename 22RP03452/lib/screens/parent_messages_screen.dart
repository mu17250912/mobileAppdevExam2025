import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentMessagesScreen extends StatefulWidget {
  final Map<String, dynamic> parentData;
  const ParentMessagesScreen({Key? key, required this.parentData}) : super(key: key);

  @override
  State<ParentMessagesScreen> createState() => _ParentMessagesScreenState();
}

class _ParentMessagesScreenState extends State<ParentMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('recipientId', isEqualTo: widget.parentData['id'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading messages'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final msg = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(msg['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('From: ${msg['senderName'] ?? ''}\n${msg['content']?.toString().substring(0, (msg['content'] as String).length > 40 ? 40 : msg['content'].length)}...'),
                trailing: Text(_formatDate(msg['createdAt'])),
                onTap: () => _openMessageDetail(context, docs[index].id, msg),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is Timestamp) dt = timestamp.toDate();
    else if (timestamp is String) dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    else return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _openMessageDetail(BuildContext context, String messageId, Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (context) => _MessageDetailDialog(
        parentData: widget.parentData,
        messageId: messageId,
        message: msg,
      ),
    );
  }
}

class _MessageDetailDialog extends StatefulWidget {
  final Map<String, dynamic> parentData;
  final String messageId;
  final Map<String, dynamic> message;
  const _MessageDetailDialog({required this.parentData, required this.messageId, required this.message});

  @override
  State<_MessageDetailDialog> createState() => _MessageDetailDialogState();
}

class _MessageDetailDialogState extends State<_MessageDetailDialog> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() { _isReplying = true; });
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': widget.parentData['id'] ?? '',
        'senderName': widget.parentData['name'] ?? '',
        'recipientId': widget.message['senderId'],
        'recipientName': widget.message['senderName'],
        'subject': 'Re: ${widget.message['subject']}',
        'content': _replyController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() { _isReplying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.message['subject'] ?? ''),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${widget.message['senderName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.message['content'] ?? ''),
            const Divider(height: 32),
            TextField(
              controller: _replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reply',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isReplying ? null : _sendReply,
          child: _isReplying
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Reply'),
        ),
      ],
    );
  }
} 