import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../widgets/job_card.dart';
import '../styles/app_styles.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';
import '../screens/my_applications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> recentNotifications = [];
  int unreadNotificationsCount = 0;
  bool isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final user = args != null ? args['user'] as AppUser? : null;
    
    if (user == null) return;

    setState(() {
      isLoadingNotifications = true;
    });

    try {
      // Load recent notifications (last 3)
      final allNotifications = await NotificationService.getUserNotifications(user.id);
      final unreadCount = await NotificationService.getUnreadNotificationsCount(user.id);
      
      setState(() {
        recentNotifications = allNotifications.take(3).toList();
        unreadNotificationsCount = unreadCount;
        isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }

  Widget _buildNotificationSection() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final user = args != null ? args['user'] as AppUser? : null;
    final isLoggedIn = args != null && args['isLoggedIn'] == true;

    if (!isLoggedIn || user == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(AppStyles.spacingM),
      child: AppStyles.primaryContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(AppStyles.spacingM),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: AppStyles.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: AppStyles.spacingS),
                  Text(
                    'Recent Notifications',
                    style: AppStyles.heading5.copyWith(
                      color: AppStyles.textPrimary,
                    ),
                  ),
                  Spacer(),
                  if (unreadNotificationsCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppStyles.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: _loadNotifications,
                    tooltip: 'Refresh notifications',
                  ),
                ],
              ),
            ),
            // Email warning banner
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
              padding: EdgeInsets.all(AppStyles.spacingS),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue[700], size: 16),
                  SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      '📧 Please check your email carefully for detailed responses from employers.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppStyles.spacingS),
            if (isLoadingNotifications)
              Padding(
                padding: EdgeInsets.all(AppStyles.spacingM),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (recentNotifications.isEmpty)
              Padding(
                padding: EdgeInsets.all(AppStyles.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: AppStyles.textMuted,
                      size: 20,
                    ),
                    SizedBox(width: AppStyles.spacingS),
                    Text(
                      'No notifications yet',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppStyles.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: recentNotifications.map((notification) {
                  final type = notification['type'] ?? 'notification';
                  final isRead = notification['isRead'] ?? false;
                  final jobTitle = notification['jobTitle'] ?? 'Unknown Job';
                  final message = notification['message'] ?? '';
                  final createdAt = notification['createdAt'] as Timestamp?;
                  final date = createdAt?.toDate();

                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppStyles.spacingM,
                      vertical: AppStyles.spacingS,
                    ),
                    padding: EdgeInsets.all(AppStyles.spacingM),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey[50] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRead ? Colors.grey[200]! : AppStyles.primaryColor.withOpacity(0.3),
                        width: isRead ? 1 : 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              type == 'status_update' ? Icons.update :
                              type == 'admin_response' ? Icons.admin_panel_settings :
                              type == 'application_deleted' ? Icons.delete_forever :
                              Icons.notifications,
                              color: type == 'status_update' ? Colors.blue :
                                     type == 'admin_response' ? Colors.orange :
                                     type == 'application_deleted' ? Colors.red :
                                     AppStyles.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: AppStyles.spacingS),
                            Expanded(
                              child: Text(
                                jobTitle,
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.textPrimary,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppStyles.errorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: AppStyles.spacingS),
                        Text(
                          message,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (date != null) ...[
                          SizedBox(height: AppStyles.spacingS),
                          Text(
                            '${date.toLocal().toString().split(' ')[0]}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppStyles.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            Padding(
              padding: EdgeInsets.all(AppStyles.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(user: user),
                          ),
                        ).then((_) {
                          _loadNotifications();
                        });
                      },
                      icon: Icon(Icons.notifications, size: 18),
                      label: Text('View All Notifications'),
                      style: AppStyles.secondaryButton,
                    ),
                  ),
                  SizedBox(width: AppStyles.spacingM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyApplicationsScreen(user: user),
                          ),
                        );
                      },
                      icon: Icon(Icons.work, size: 18),
                      label: Text('My Applications'),
                      style: AppStyles.secondaryButton,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final bool isAdmin = args != null && args['isAdmin'] == true;
    final bool isLoggedIn = args != null && args['isLoggedIn'] == true;
    final String? userEmail = args != null ? args['userEmail'] : null;
    final user = args != null ? args['user'] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Listings'),
        elevation: 0,
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: Icon(Icons.dashboard),
              tooltip: 'Dashboard',
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            IconButton(
              icon: Icon(Icons.people_outline),
              tooltip: 'All Users',
              onPressed: () {
                Navigator.pushNamed(context, '/adminUsers');
              },
            ),
          ],
          Builder(
            builder: (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map?;
              final user = args != null ? args['user'] as AppUser? : null;
              if (user == null) return SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(user: user),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.work),
                    tooltip: 'My Applications',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyApplicationsScreen(user: user),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          // REMOVE the profile icon/button entirely for all users
          IconButton(
            icon: Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/me.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppStyles.primaryColor.withOpacity(0.1),
                  AppStyles.backgroundPrimary,
                ],
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
                        ),
                        AppStyles.verticalSpaceM,
                        Text(
                          'Loading jobs...',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppStyles.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: AppStyles.primaryContainer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: AppStyles.textMuted,
                          ),
                          AppStyles.verticalSpaceM,
                          Text(
                            'No Jobs Available',
                            style: AppStyles.heading4.copyWith(
                              color: AppStyles.textTertiary,
                            ),
                          ),
                          AppStyles.verticalSpaceS,
                          Text(
                            'Check back later for new opportunities',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppStyles.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final jobs = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Job(
                    id: doc.id,
                    title: data['title'] ?? '',
                    company: data['company'] ?? '',
                    location: data['location'] ?? '',
                    description: data['description'] ?? '',
                    requirements: List<String>.from(data['requirements'] ?? []),
                    salary: data['salary'] ?? '',
                    jobType: data['jobType'] ?? '',
                    experienceLevel: data['experienceLevel'] ?? '',
                    deadline: data['deadline'] ?? '',
                    applicants: [], // You can load applicants if needed
                  );
                }).toList();
                
                return ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spacingM),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return AppStyles.primaryContainer(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/jobDetail',
                                arguments: {
                                  'job': jobs[index],
                                  'isLoggedIn': isLoggedIn,
                                  'userEmail': userEmail,
                                  'user': user,
                                  'isAdmin': isAdmin,
                                },
                              );
                            },
                            child: JobCard(job: jobs[index]),
                          ),
                          if (isAdmin) ...[
                            AppStyles.divider,
                            Padding(
                              padding: const EdgeInsets.all(AppStyles.spacingM),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/applicants',
                                          arguments: jobs[index],
                                        );
                                      },
                                      icon: Icon(Icons.people_outline, size: 18),
                                      label: Text('View Applicants'),
                                      style: AppStyles.secondaryButton,
                                    ),
                                  ),
                                  AppStyles.horizontalSpaceM,
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: AppStyles.errorColor),
                                    tooltip: 'Delete Job',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            'Delete Job',
                                            style: AppStyles.heading5,
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete "${jobs[index].title}"? This action cannot be undone.',
                                            style: AppStyles.bodyMedium,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppStyles.errorColor,
                                              ),
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('jobs').doc(jobs[index].id).delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Job deleted successfully'),
                                            backgroundColor: AppStyles.successColor,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, '/addJob');
              },
              icon: Icon(Icons.add),
              label: Text('Add Job'),
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
} 