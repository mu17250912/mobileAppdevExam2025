import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/skill_model.dart';
import 'chat_screen.dart';

class RequestedSkillsScreen extends StatefulWidget {
  final List<Skill>? requests;
  final Skill? initialSkill;
  const RequestedSkillsScreen({super.key, this.requests, this.initialSkill});

  @override
  State<RequestedSkillsScreen> createState() => _RequestedSkillsScreenState();
}

class _RequestedSkillsScreenState extends State<RequestedSkillsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Skill> _requestedSkills = [];
  bool _isLoading = true;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.requests != null && widget.requests!.isNotEmpty) {
      _requestedSkills = widget.requests!;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialSkill != null) {
          final idx = _requestedSkills
              .indexWhere((s) => s.id == widget.initialSkill!.id);
          if (idx != -1) {
            _scrollController.animateTo(
              idx * 120.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    } else {
      _loadRequestedSkills();
    }
  }

  Future<void> _loadRequestedSkills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final querySnapshot = await _firestore
          .collection('skills')
          .where('type', isEqualTo: 'want')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final skills =
          querySnapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();

      setState(() {
        _requestedSkills = skills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load requested skills: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectWithUser(Skill skill) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if user is trying to connect with themselves
      if (currentUser.uid == skill.userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot connect with yourself'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: skill.userId,
            receiverName: skill.userName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSkillCard(Skill skill) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: skill.userPhotoUrl.isNotEmpty
                      ? NetworkImage(skill.userPhotoUrl)
                      : null,
                  child: skill.userPhotoUrl.isEmpty
                      ? Text(
                          skill.userName.isNotEmpty
                              ? skill.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Wants to learn: ${skill.name}',
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    skill.difficulty,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              skill.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (skill.tags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: skill.tags
                    .take(3)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  skill.location.isNotEmpty ? skill.location : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _connectWithUser(skill),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
        title: const Text('Requested Skills'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequestedSkills,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _requestedSkills.length,
                  itemBuilder: (context, index) {
                    final skill = _requestedSkills[index];
                    return _buildSkillCard(skill);
                  },
                ),
    );
  }
}
