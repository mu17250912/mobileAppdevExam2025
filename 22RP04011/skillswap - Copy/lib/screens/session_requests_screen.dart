import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_model.dart';
import '../services/app_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class SessionRequestsScreen extends StatefulWidget {
  const SessionRequestsScreen({super.key});

  @override
  State<SessionRequestsScreen> createState() => _SessionRequestsScreenState();
}

class _SessionRequestsScreenState extends State<SessionRequestsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<SessionModel> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final requests = await AppService.getPendingSessionRequests(user.uid);
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load session requests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToRequest(SessionModel session, bool accepted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final success = await AppService.respondToSessionRequest(
        sessionId: session.id,
        responderId: user.uid,
        accepted: accepted,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepted
                  ? 'Session request accepted!'
                  : 'Session request declined.',
            ),
            backgroundColor: accepted ? Colors.green : Colors.orange,
          ),
        );

        // Remove from list
        setState(() {
          _pendingRequests.removeWhere((s) => s.id == session.id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to respond to request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResponseDialog(SessionModel session) async {
    final messageController = TextEditingController();
    bool accepted = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Respond to Session Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session: ${session.title}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('From: ${session.hostName}'),
              const SizedBox(height: 8),
              Text(
                  'Scheduled: ${DateFormat('MMM dd, yyyy - HH:mm').format(session.scheduledAt)}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Accept'),
                      value: true,
                      groupValue: accepted,
                      onChanged: (value) {
                        setDialogState(() => accepted = value!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Decline'),
                      value: false,
                      groupValue: accepted,
                      onChanged: (value) {
                        setDialogState(() => accepted = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Optional message',
                  hintText:
                      accepted ? 'Add a note...' : 'Reason for declining...',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToRequest(session, accepted);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accepted ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(accepted ? 'Accept' : 'Decline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(SessionModel session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    session.hostName.isNotEmpty
                        ? session.hostName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.hostName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Session Request',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                session.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm')
                      .format(session.scheduledAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${session.duration} min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: session.hostId,
                            receiverName: session.hostName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResponseDialog(session),
                    icon: const Icon(Icons.check),
                    label: const Text('Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Requests'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingRequests,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No pending session requests',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see session requests here when users want to schedule sessions with you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _pendingRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(_pendingRequests[index]);
                        },
                      ),
                    ),
    );
  }
}
