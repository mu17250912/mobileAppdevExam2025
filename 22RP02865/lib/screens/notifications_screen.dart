import 'package:flutter/material.dart';
import '../services/task_storage.dart';
import '../models/task.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.tasks;
          final upcomingTasks = taskProvider.getUpcomingTasks();

          return RefreshIndicator(
            onRefresh: () => taskProvider.refresh(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Tasks Section
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
                              Icon(Icons.schedule, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Upcoming Tasks',
                                style: AppTextStyles.subheading.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (upcomingTasks.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 48,
                                    color: Colors.green.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No upcoming tasks!',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You\'re all caught up',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...upcomingTasks.take(5).map((task) => _NotificationItem(
                              task: task,
                              type: NotificationType.upcoming,
                            )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity Section
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
                              Icon(Icons.history, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Activity',
                                style: AppTextStyles.subheading.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (tasks.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.task_outlined,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No tasks yet',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (!taskProvider.hasCachedData) ...[
                                    const SizedBox(height: 16),
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Loading tasks...',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            ...tasks.take(10).map((task) => _NotificationItem(
                              task: task,
                              type: task.isCompleted 
                                ? NotificationType.completed 
                                : NotificationType.pending,
                            )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats
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
                          Text(
                            'Quick Stats',
                            style: AppTextStyles.subheading.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                icon: Icons.task,
                                label: 'Total Tasks',
                                value: '${taskProvider.totalTasksCount}',
                                color: AppColors.primary,
                              ),
                              _StatItem(
                                icon: Icons.check_circle,
                                label: 'Completed',
                                value: '${taskProvider.completedTasksCount}',
                                color: Colors.green,
                              ),
                              _StatItem(
                                icon: Icons.schedule,
                                label: 'Upcoming',
                                value: '${upcomingTasks.length}',
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading indicator for background sync
                  if (!taskProvider.hasCachedData) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Syncing notification data...',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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

enum NotificationType { upcoming, completed, pending }

class _NotificationItem extends StatelessWidget {
  final Task task;
  final NotificationType type;

  const _NotificationItem({
    required this.task,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String subtitle;

    switch (type) {
      case NotificationType.upcoming:
        icon = Icons.schedule;
        color = Colors.orange;
        subtitle = 'Upcoming: ${_formatDateTime(task.dateTime)}';
        break;
      case NotificationType.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        subtitle = 'Completed: ${_formatDateTime(task.dateTime)}';
        break;
      case NotificationType.pending:
        icon = Icons.pending;
        color = Colors.grey;
        subtitle = 'Pending: ${_formatDateTime(task.dateTime)}';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.subject,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${task.duration}min',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} from now';
    } else {
      return 'Just now';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading.copyWith(
            fontSize: 24,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 