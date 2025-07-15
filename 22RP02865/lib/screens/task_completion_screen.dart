import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/analytics_service.dart';
import '../theme.dart';
import 'dart:async';

class TaskCompletionScreen extends StatefulWidget {
  final Task task;
  
  const TaskCompletionScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isCompleted = false;
  double _progress = 0.0;
  final AnalyticsService _analytics = AnalyticsService();
  
  // Completion methods
  final List<String> _completionMethods = [
    'Timer-based completion',
    'Manual completion',
    'Partial completion',
    'Skip task',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    // Check if task was already started
    final startTime = widget.task.dateTime;
    final now = DateTime.now();
    if (startTime.isBefore(now)) {
      _elapsedSeconds = now.difference(startTime).inSeconds;
      _progress = (_elapsedSeconds / (widget.task.duration * 60)).clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (!_isTimerRunning) {
      _isTimerRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          _progress = (_elapsedSeconds / (widget.task.duration * 60)).clamp(0.0, 1.0);
          
          // Auto-complete when time is reached
          if (_elapsedSeconds >= widget.task.duration * 60) {
            _completeTask('Timer-based completion');
          }
        });
      });
    }
  }

  void _pauseTimer() {
    if (_isTimerRunning) {
      _isTimerRunning = false;
      _timer.cancel();
    }
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _elapsedSeconds = 0;
      _progress = 0.0;
    });
  }

  void _completeTask(String method) async {
    if (_isCompleted) return;
    
    setState(() {
      _isCompleted = true;
    });
    
    _pauseTimer();
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    widget.task.isCompleted = true;
    
    try {
      await taskProvider.updateTask(widget.task);
      
      // Track completion analytics
      await _analytics.trackTaskCompleted(widget.task.subject);
      await _analytics.trackUserEngagement('task_completion_method_$method');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _completionMethods.map((method) => ListTile(
            leading: Icon(_getMethodIcon(method)),
            title: Text(method),
            onTap: () {
              Navigator.pop(context);
              _handleCompletionMethod(method);
            },
          )).toList(),
        ),
      ),
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'Timer-based completion':
        return Icons.timer;
      case 'Manual completion':
        return Icons.check_circle;
      case 'Partial completion':
        return Icons.assignment_turned_in;
      case 'Skip task':
        return Icons.skip_next;
      default:
        return Icons.check;
    }
  }

  void _handleCompletionMethod(String method) {
    switch (method) {
      case 'Timer-based completion':
        if (_elapsedSeconds >= widget.task.duration * 60) {
          _completeTask(method);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Complete the timer first (${widget.task.duration} minutes)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
      case 'Manual completion':
        _completeTask(method);
        break;
      case 'Partial completion':
        _showPartialCompletionDialog();
        break;
      case 'Skip task':
        _showSkipConfirmation();
        break;
    }
  }

  void _showPartialCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Partial Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How much of the task did you complete?'),
            SizedBox(height: 16),
            Slider(
              value: _progress,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_progress * 100).toInt()}%',
              onChanged: (value) {
                setState(() {
                  _progress = value;
                });
              },
            ),
            Text('${(_progress * 100).toInt()}% completed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTask('Partial completion (${(_progress * 100).toInt()}%)');
            },
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Task'),
        content: Text('Are you sure you want to skip this task? It will be marked as completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTask('Skip task');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Skip'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (widget.task.duration * 60) - _elapsedSeconds;
    final isTimeUp = remainingSeconds <= 0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Complete Task'),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle),
            onPressed: _isCompleted ? null : _showCompletionDialog,
            tooltip: 'Complete Task',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.task, color: Colors.blue[800], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.task.subject,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 20,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (widget.task.notes.isNotEmpty) ...[
                      Text(
                        widget.task.notes,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange[800], size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${widget.task.duration} minutes',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Timer Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Progress Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isTimeUp ? Colors.green : Colors.blue[800]!,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              _formatTime(_elapsedSeconds),
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 32,
                                color: isTimeUp ? Colors.green : Colors.blue[800],
                              ),
                            ),
                            Text(
                              'of ${_formatTime(widget.task.duration * 60)}',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Timer Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isCompleted ? null : (_isTimerRunning ? _pauseTimer : _startTimer),
                          icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTimerRunning ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isCompleted ? null : _resetTimer,
                          icon: Icon(Icons.refresh),
                          label: Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Completion Status
                    if (isTimeUp && !_isCompleted)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Time completed! You can now finish the task.',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Completion Methods
            Text(
              'Completion Methods',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12),
            
            ..._completionMethods.map((method) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getMethodColor(method).withOpacity(0.1),
                  child: Icon(
                    _getMethodIcon(method),
                    color: _getMethodColor(method),
                  ),
                ),
                title: Text(method),
                subtitle: Text(_getMethodDescription(method)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _isCompleted ? null : () => _handleCompletionMethod(method),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'Timer-based completion':
        return Colors.green;
      case 'Manual completion':
        return Colors.blue;
      case 'Partial completion':
        return Colors.orange;
      case 'Skip task':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMethodDescription(String method) {
    switch (method) {
      case 'Timer-based completion':
        return 'Complete after using the timer for the full duration';
      case 'Manual completion':
        return 'Mark as completed immediately';
      case 'Partial completion':
        return 'Mark as partially completed with custom progress';
      case 'Skip task':
        return 'Skip this task and mark as completed';
      default:
        return '';
    }
  }
} 