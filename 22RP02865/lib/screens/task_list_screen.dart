import 'package:flutter/material.dart';
import '../services/task_storage.dart';
import '../widgets/task_tile.dart';
import '../widgets/offline_indicator.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final taskStorage = TaskStorage();
  bool _isSyncing = false;
  bool _hasSyncError = false;
  String _lastError = '';

  Future<void> _syncWithFirebase() async {
    if (_isSyncing) return; // Prevent multiple simultaneous syncs
    
    setState(() {
      _isSyncing = true;
      _hasSyncError = false;
      _lastError = '';
    });

    try {
      // Check connectivity first
      final canConnect = await taskStorage.canConnectToFirebase();
      if (!canConnect) {
        throw Exception('Cannot connect to Firebase. Please check your internet connection and try again.');
      }
      
      // First, try to sync with Firebase
      await taskStorage.syncWithFirebase();
      
      // Then refresh the task provider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.refresh();
      
      if (mounted) {
        // Clear any previous sync errors
        setState(() {
          _hasSyncError = false;
          _lastError = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks synced successfully with Firebase!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Sync error: $e');
      if (mounted) {
        setState(() {
          _hasSyncError = true;
          _lastError = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _syncWithFirebase,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Use immediate data access - no async operations
          final tasks = taskProvider.getTasksImmediately();
          final hasData = taskProvider.hasCachedData || tasks.isNotEmpty;
          final isInitialized = taskProvider.isInitialized;
          final isLoading = taskProvider.isLoading;

          // Show empty state if no tasks
          if (tasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                try {
                  await taskProvider.refresh();
                } catch (e) {
                  print('Refresh error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Refresh failed: ${e.toString()}'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_outlined,
                            size: 64,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet!\nAdd a new task to get started.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary.withOpacity(0.7)
                            ),
                          ),
                          // Show loading indicator only when truly loading and no data
                          if (isLoading && !hasData && !isInitialized) ...[
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
                          // Show sync error if there was one
                          if (_hasSyncError) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Sync Error',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _lastError.length > 50 
                                        ? '${_lastError.substring(0, 50)}...' 
                                        : _lastError,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.red[600],
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _syncWithFirebase,
                            icon: _isSyncing 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync with Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              try {
                await taskProvider.refresh();
              } catch (e) {
                print('Refresh error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Refresh failed: ${e.toString()}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: Column(
              children: [
                // Sync status and button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                              style: AppTextStyles.subheading.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            if (_hasSyncError)
                              Text(
                                'Last sync failed',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.red[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _syncWithFirebase,
                        icon: _isSyncing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: Text(_isSyncing ? 'Syncing...' : 'Sync'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasSyncError ? Colors.red : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Task list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: TaskTile(
                            task: tasks[index],
                            onChanged: () {
                              // No need to reload all tasks, the provider handles updates
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
