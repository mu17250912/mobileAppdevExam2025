import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../providers/auth_provider.dart';
import 'add_task_screen.dart';
import 'task_list_screen.dart';
import 'timer_screen.dart';
import 'study_goal_screen.dart';
import 'task_completion_screen.dart';
import '../theme.dart';
import '../services/task_storage.dart';
import '../models/study_goal.dart';
import '../providers/task_provider.dart';
import 'feedback_form_screen.dart';
import 'login_screen.dart';
import '../providers/premium_provider.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import '../services/hive_service.dart';
import '../widgets/ad_banner_widget.dart';
import 'premium_screen.dart';
import 'premium_features_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final AdService _adService = AdService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Use immediate data access - no async operations
          final tasks = taskProvider.getTasksImmediately();
          final completedTasks = taskProvider.completedTasksCount;
          final totalTasks = taskProvider.totalTasksCount;
          final progress = taskProvider.progressPercentage;

          // Badge logic: show badge if all tasks are completed and at least one task exists
          final hasBadge = totalTasks > 0 && completedTasks == totalTasks;

          // Get study goal safely
          final goalBox = HiveService().getStudyGoalsBoxSync();
          final StudyGoal? goal = goalBox?.isNotEmpty == true ? goalBox?.getAt(0) : null;

          return RefreshIndicator(
            onRefresh: () => taskProvider.refresh(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.blue[800]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        final user = authProvider.user;
                                        final userName = user?.displayName ?? 
                                                       user?.email?.split('@')[0] ?? 
                                                       'Student';
                                        
                                        return Text(
                                          'Welcome back, $userName!',
                                          style: AppTextStyles.heading.copyWith(
                                            color: Colors.white,
                                            fontSize: 24,
                                          ),
                                        );
                                      },
                                    ),
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        final user = authProvider.user;
                                        final userName = user?.displayName ?? 
                                                       user?.email?.split('@')[0] ?? 
                                                       'Student';
                                        
                                        return Text(
                                          'Ready to study, $userName?',
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (hasBadge)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return IconButton(
                                    onPressed: authProvider.isLoading ? null : () async {
                                      // Show confirmation dialog
                                      final shouldLogout = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Logout'),
                                          content: const Text('Are you sure you want to logout?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('Logout'),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (shouldLogout == true && mounted) {
                                        try {
                                          await authProvider.signOut();
                                          if (mounted) {
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (_) => LoginScreen()),
                                              (route) => false,
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Logout failed: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.logout,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                    tooltip: 'Logout',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.task,
                                  label: 'Total Tasks',
                                  value: '$totalTasks',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.check_circle,
                                  label: 'Completed',
                                  value: '$completedTasks',
                                  color: Colors.green[100]!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Section
                  if (totalTasks > 0) ...[
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Progress',
                                  style: AppTextStyles.subheading.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${completedTasks} of $totalTasks tasks completed',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeActionCard(
                          icon: Icons.add_task,
                          label: 'Add Task',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddTaskScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _HomeActionCard(
                          icon: Icons.timer,
                          label: 'Start Timer',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TimerScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeActionCard(
                          icon: Icons.flag,
                          label: 'Set Goal',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StudyGoalScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _HomeActionCard(
                          icon: Icons.feedback,
                          label: 'Feedback',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FeedbackFormScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Premium Upgrade Prompt (for non-premium users)
                  Consumer<PremiumProvider>(
                    builder: (context, premiumProvider, child) {
                      if (!premiumProvider.isPremium && tasks.length >= 5) {
                        return Column(
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [Colors.amber[600]!, Colors.amber[400]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Unlock Premium Features',
                                                style: AppTextStyles.body.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Remove ads and get unlimited tasks',
                                                style: AppTextStyles.body.copyWith(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/premium');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.amber[600],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Upgrade',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Recent Tasks
                  if (tasks.isNotEmpty) ...[
                    Text(
                      'Recent Tasks',
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...tasks.take(3).map((task) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.isCompleted 
                            ? Colors.green[100] 
                            : Colors.orange[100],
                          child: Icon(
                            task.isCompleted ? Icons.check : Icons.schedule,
                            color: task.isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          task.subject,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                          ),
                        ),
                        subtitle: Text(
                          '${task.dateTime.toString().split(' ')[0]} • ${task.duration}min',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: task.isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_circle, color: Colors.green[600]),
                                    onPressed: () async {
                                      // Show interstitial ad for non-premium users
                                      await InterstitialAdManager.showAdIfNeeded();
                                      
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TaskCompletionScreen(task: task),
                                        ),
                                      );
                                      if (result == true) {
                                        // Refresh the task provider
                                        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                                        await taskProvider.refresh();
                                      }
                                    },
                                    tooltip: 'Complete Task',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.check_circle_outline, color: Colors.blue[600]),
                                    onPressed: () async {
                                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                                      task.isCompleted = true;
                                      await taskProvider.updateTask(task);
                                    },
                                    tooltip: 'Quick Complete',
                                  ),
                                ],
                              ),
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Ad Banner (for non-premium users)
                  const AdBannerWidget(
                    height: 60,
                    margin: EdgeInsets.symmetric(vertical: 16),
                  ),

                  // Loading indicator for background sync
                  if (!taskProvider.hasCachedData) ...[
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Syncing data...',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}