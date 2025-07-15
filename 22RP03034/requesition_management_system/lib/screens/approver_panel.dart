import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'request_details_screen.dart';
import '../models/request_model.dart';
import '../widgets/app_drawer.dart';

class ApproverPanel extends StatefulWidget {
  const ApproverPanel({super.key});

  @override
  State<ApproverPanel> createState() => _ApproverPanelState();
}

class _ApproverPanelState extends State<ApproverPanel> {
  List<Request> _requests = [];
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRequests();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['name'] ?? '';
            _userEmail = userData['email'] ?? '';
            _profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', whereIn: ['For Approval', 'Approved'])
          .get();

      final requests = querySnapshot.docs.map((doc) {
        return Request.fromFirestore(doc.data(), doc.id);
      }).toList();

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest(String requestId, String comment) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'Approved',
        'approverComment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to history
      final request = _requests.firstWhere((r) => r.id == requestId);
      request.addHistory('Approved', _userName, comment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully')),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId, String comment) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'Rejected',
        'approverComment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to history
      final request = _requests.firstWhere((r) => r.id == requestId);
      request.addHistory('Rejected', _userName, comment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  Future<void> _showApprovalDialog(Request request) async {
    final commentController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${request.subject}'),
            Text('Employee: ${request.employeeName}'),
            Text('Description: ${request.description}'),
            if (request.quantity != null) Text('Requested: ${request.quantity}'),
            if (request.availableQuantity != null) Text('Available: ${request.availableQuantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Add approval/rejection reason',
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
          TextButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context, {
                'action': 'reject',
                'comment': commentController.text.trim(),
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'action': 'approve',
                'comment': commentController.text.trim(),
              });
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      if (result['action'] == 'approve') {
        await _approveRequest(request.id, result['comment']!);
      } else if (result['action'] == 'reject') {
        await _rejectRequest(request.id, result['comment']!);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
          await storageRef.putFile(File(pickedFile.path));
          final downloadUrl = await storageRef.getDownloadURL();

          // Update user profile in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'profileImage': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _profileImageUrl = downloadUrl;
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return const AssetImage('assets/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approver Panel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      drawer: AppDrawer(
        userName: _userName,
        userEmail: _userEmail,
        profileImageUrl: _profileImageUrl,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _getProfileImage(),
                              onBackgroundImageError: (exception, stackTrace) {
                                debugPrint('Error loading profile image: $exception');
                              },
                            ),
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Approver',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section
                Expanded(
                  child: _requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No requests to approve',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Requests forwarded by logistics will appear here',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadRequests,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final request = _requests[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    request.subject,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text('Employee: ${request.employeeName}'),
                                      Text('Date: ${request.date.toString().split(' ')[0]}'),
                                      if (request.quantity != null) Text('Requested: ${request.quantity}'),
                                      if (request.availableQuantity != null) Text('Available: ${request.availableQuantity}'),
                                      if (request.logisticsComment != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Logistics Note: ${request.logisticsComment}'),
                                      ],
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Pending Approval',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RequestDetailsScreen(request: request, index: index),
                                            ),
                                          );
                                        },
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showApprovalDialog(request),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Review'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
} 