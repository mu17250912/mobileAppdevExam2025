import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final userData = _userData!;
    final userName = userData['name'] ?? 'Unknown User';
    final userEmail = userData['email'] ?? '';
    final userAvatar = userData['avatar'] ?? '';
    final isOnline = userData['isOnline'] ?? false;
    final lastSeen = userData['lastSeen'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // TODO: Navigate to direct message
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Stats'),
            Tab(text: 'Shared'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(
            userName: userName,
            userEmail: userEmail,
            userAvatar: userAvatar,
            isOnline: isOnline,
            lastSeen: lastSeen,
          ),
          _StatsTab(userId: widget.userId),
          _SharedTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userAvatar;
  final bool isOnline;
  final dynamic lastSeen;

  const _InfoTab({
    required this.userName,
    required this.userEmail,
    required this.userAvatar,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userAvatar.isNotEmpty
                          ? NetworkImage(userAvatar)
                          : null,
                      child: userAvatar.isEmpty
                          ? Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (lastSeen != null && !isOnline) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last seen ${_formatLastSeen(lastSeen)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Study preferences
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Study Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _PreferenceItem(
                  icon: Icons.schedule,
                  title: 'Preferred Study Time',
                  value: 'Evening (6 PM - 10 PM)',
                ),
                const SizedBox(height: 12),
                _PreferenceItem(
                  icon: Icons.timer,
                  title: 'Study Session Duration',
                  value: '45 minutes',
                ),
                const SizedBox(height: 12),
                _PreferenceItem(
                  icon: Icons.subject,
                  title: 'Favorite Subjects',
                  value: 'Mathematics, Physics',
                ),
                const SizedBox(height: 12),
                _PreferenceItem(
                  icon: Icons.group,
                  title: 'Study Style',
                  value: 'Group study preferred',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen is Timestamp) {
      final now = DateTime.now();
      final lastSeenTime = lastSeen.toDate();
      final difference = now.difference(lastSeenTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    }
    return 'Unknown';
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PreferenceItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String userId;

  const _StatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final stats = userData['stats'] ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Study statistics
              _StatCard(
                title: 'Study Statistics',
                children: [
                  _StatItem(
                    icon: Icons.timer,
                    title: 'Total Study Hours',
                    value: '${stats['totalStudyHours'] ?? 0}h',
                    color: AppTheme.primaryColor,
                  ),
                  _StatItem(
                    icon: Icons.task_alt,
                    title: 'Tasks Completed',
                    value: '${stats['tasksCompleted'] ?? 0}',
                    color: Colors.green,
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    title: 'Current Streak',
                    value: '${stats['currentStreak'] ?? 0} days',
                    color: Colors.orange,
                  ),
                  _StatItem(
                    icon: Icons.emoji_events,
                    title: 'Achievements',
                    value: '${stats['achievements'] ?? 0}',
                    color: Colors.purple,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Weekly progress
              _StatCard(
                title: 'This Week',
                children: [
                  _StatItem(
                    icon: Icons.calendar_today,
                    title: 'Study Sessions',
                    value: '${stats['weeklySessions'] ?? 0}',
                    color: Colors.blue,
                  ),
                  _StatItem(
                    icon: Icons.schedule,
                    title: 'Study Hours',
                    value: '${stats['weeklyHours'] ?? 0}h',
                    color: Colors.teal,
                  ),
                  _StatItem(
                    icon: Icons.check_circle,
                    title: 'Goals Met',
                    value: '${stats['weeklyGoals'] ?? 0}',
                    color: Colors.green,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Subject breakdown
              _StatCard(
                title: 'Subject Breakdown',
                children: [
                  _SubjectProgress(
                    subject: 'Mathematics',
                    progress: 0.8,
                    color: Colors.red,
                  ),
                  _SubjectProgress(
                    subject: 'Physics',
                    progress: 0.6,
                    color: Colors.blue,
                  ),
                  _SubjectProgress(
                    subject: 'Chemistry',
                    progress: 0.9,
                    color: Colors.green,
                  ),
                  _SubjectProgress(
                    subject: 'Biology',
                    progress: 0.7,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  final String subject;
  final double progress;
  final Color color;

  const _SubjectProgress({
    required this.subject,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}

class _SharedTab extends StatelessWidget {
  final String userId;

  const _SharedTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sharedContent')
          .orderBy('sharedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final sharedItems = snapshot.data?.docs ?? [];

        if (sharedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.share,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No shared content yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This user hasn\'t shared any content',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sharedItems.length,
          itemBuilder: (context, index) {
            final item = sharedItems[index].data() as Map<String, dynamic>;
            return _SharedItemCard(
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              type: item['type'] ?? '',
              sharedAt: item['sharedAt'],
            );
          },
        );
      },
    );
  }
}

class _SharedItemCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final dynamic sharedAt;

  const _SharedItemCard({
    required this.title,
    required this.description,
    required this.type,
    required this.sharedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getTypeLabel(type),
                style: TextStyle(
                  fontSize: 12,
                  color: _getTypeColor(type),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(sharedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Icons.flag;
      case 'resource':
        return Icons.link;
      case 'note':
        return Icons.note;
      case 'flashcard':
        return Icons.style;
      default:
        return Icons.share;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Colors.blue;
      case 'resource':
        return Colors.green;
      case 'note':
        return Colors.orange;
      case 'flashcard':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return 'Study Goal';
      case 'resource':
        return 'Resource';
      case 'note':
        return 'Note';
      case 'flashcard':
        return 'Flashcard';
      default:
        return 'Shared';
    }
  }

  String _formatTime(dynamic sharedAt) {
    if (sharedAt is Timestamp) {
      final now = DateTime.now();
      final sharedTime = sharedAt.toDate();
      final difference = now.difference(sharedTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return 'Unknown';
  }
}
