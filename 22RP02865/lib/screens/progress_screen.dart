import 'package:flutter/material.dart';
import '../services/task_storage.dart';
import '../models/task.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.tasks;
          final completedTasks = tasks.where((t) => t.isCompleted).toList();
          final totalTasks = tasks.length;
          final today = DateTime.now();
          final todayTasks = taskProvider.getTasksByDate(today);
          final todayCompleted = todayTasks.where((t) => t.isCompleted).length;
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          final weekTasks = tasks.where((t) => t.dateTime.isAfter(weekStart)).toList();
          final weekCompleted = weekTasks.where((t) => t.isCompleted).length;
          int dailyMinutes = todayCompleted * 30; // Assume each task is 30min for demo
          int weeklyMinutes = weekCompleted * 30;

          return RefreshIndicator(
            onRefresh: () => taskProvider.refresh(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Progress Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Overall Progress',
                            style: AppTextStyles.heading.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: totalTasks == 0 ? 0.0 : completedTasks.length / totalTasks,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${completedTasks.length}',
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 28,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'of $totalTasks',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Progress
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
                              Icon(Icons.today, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                "Today's Progress",
                                style: AppTextStyles.subheading.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ProgressStat(
                                label: 'Tasks',
                                value: '${todayTasks.length}',
                                icon: Icons.task,
                              ),
                              _ProgressStat(
                                label: 'Completed',
                                value: '$todayCompleted',
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                              _ProgressStat(
                                label: 'Minutes',
                                value: '$dailyMinutes',
                                icon: Icons.timer,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Progress
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
                              Icon(Icons.calendar_view_week, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Weekly Progress',
                                style: AppTextStyles.subheading.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ProgressStat(
                                label: 'Tasks',
                                value: '${weekTasks.length}',
                                icon: Icons.task,
                              ),
                              _ProgressStat(
                                label: 'Completed',
                                value: '$weekCompleted',
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                              _ProgressStat(
                                label: 'Minutes',
                                value: '$weeklyMinutes',
                                icon: Icons.timer,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Completed Tasks
                  if (completedTasks.isNotEmpty) ...[
                    Text(
                      'Recently Completed',
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...completedTasks.take(5).map((task) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.check, color: Colors.green),
                        ),
                        title: Text(task.subject),
                        subtitle: Text(
                          'Completed on ${task.dateTime.toString().split(' ')[0]}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '${task.duration}min',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
                  ],

                  // Loading indicator for background sync
                  if (!taskProvider.hasCachedData) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Syncing progress data...',
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

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading.copyWith(
            fontSize: 24,
            color: color ?? AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 