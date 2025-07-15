import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'course_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;
  
  const NotificationsScreen({
    Key? key, 
    required this.userEmail, 
    required this.userRole
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      List<Map<String, dynamic>> allNotifications = [];

      // Load connection requests
      final connectionRequests = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where(widget.userRole == 'trainer' ? 'trainerEmail' : 'learnerEmail', isEqualTo: widget.userEmail)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in connectionRequests.docs) {
        final data = doc.data();
        allNotifications.add({
          'id': doc.id,
          'type': 'connection_request',
          'title': 'New Connection Request',
          'message': widget.userRole == 'trainer' 
              ? '${data['learnerName']} wants to connect with you'
              : '${data['trainerName']} wants to connect with you',
          'timestamp': data['createdAt'],
          'data': data,
        });
      }

      // Load course completions (for trainers)
      if (widget.userRole == 'trainer') {
        final courseCompletions = await FirebaseFirestore.instance
            .collection('completed_courses')
            .where('trainerEmail', isEqualTo: widget.userEmail)
            .orderBy('completedAt', descending: true)
            .limit(10)
            .get();

        for (var doc in courseCompletions.docs) {
          final data = doc.data();
          allNotifications.add({
            'id': doc.id,
            'type': 'course_completion',
            'title': 'Course Completed',
            'message': '${data['userEmail']?.split('@')[0]} completed your course "${data['courseTitle']}"',
            'timestamp': data['completedAt'],
            'data': data,
          });
        }
      }

      // Load new courses (for learners)
      if (widget.userRole == 'learner') {
        final newCourses = await FirebaseFirestore.instance
            .collection('courses')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        for (var doc in newCourses.docs) {
          final data = doc.data();
          allNotifications.add({
            'id': doc.id,
            'type': 'new_course',
            'title': 'New Course Available',
            'message': 'New course "${data['title']}" by ${data['trainerName']}',
            'timestamp': data['createdAt'],
            'data': data,
          });
        }
      }

      // Sort by timestamp
      allNotifications.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        notifications = allNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'connection_request':
        return Icons.people;
      case 'course_completion':
        return Icons.school;
      case 'new_course':
        return Icons.book;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'connection_request':
        return Colors.blue;
      case 'course_completion':
        return Colors.green;
      case 'new_course':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.userRole == 'trainer' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: notification['type'] == 'new_course'
              ? () {
                  final courseData = notification['data'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(
                        userEmail: widget.userEmail,
                        userRole: widget.userRole,
                        course: {...courseData, 'id': notification['id']},
                      ),
                    ),
                  );
                }
              : null,
            leading: CircleAvatar(
              backgroundColor: _getNotificationColor(notification['type']).withOpacity(0.1),
              child: Icon(
                _getNotificationIcon(notification['type']),
                color: _getNotificationColor(notification['type']),
              ),
            ),
            title: Text(
              notification['title'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['message'],
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification['timestamp']),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: notification['type'] == 'connection_request'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleConnectionRequest(notification, 'accept'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleConnectionRequest(notification, 'reject'),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _handleConnectionRequest(Map<String, dynamic> notification, String action) async {
    try {
      final requestData = notification['data'];
      
      if (action == 'accept') {
        // Update request status
        await FirebaseFirestore.instance
            .collection('connection_requests')
            .doc(notification['id'])
            .update({
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create connection
        await FirebaseFirestore.instance.collection('connections').add({
          'trainerEmail': requestData['trainerEmail'],
          'learnerEmail': requestData['learnerEmail'],
          'trainerName': requestData['trainerName'],
          'learnerName': requestData['learnerName'],
          'status': 'connected',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request accepted!')),
        );
      } else {
        // Reject request
        await FirebaseFirestore.instance
            .collection('connection_requests')
            .doc(notification['id'])
            .update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request rejected!')),
        );
      }

      _loadNotifications(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling request: $e')),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
} 