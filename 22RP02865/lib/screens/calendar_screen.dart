import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme.dart';
import 'add_task_screen.dart';
import 'task_completion_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, List<Task>> _events;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _events = {};
    _loadEvents();
  }

  void _loadEvents() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.tasks;
    
    _events.clear();
    for (final task in tasks) {
      final date = DateTime(task.dateTime.year, task.dateTime.month, task.dateTime.day);
      if (_events[date] == null) _events[date] = [];
      _events[date]!.add(task);
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        actions: [
          PopupMenuButton<CalendarFormat>(
            icon: Icon(Icons.view_module),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Month'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Week'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 Weeks'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Widget
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getTasksForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue[800],
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        width: 8,
                        height: 8,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          
          // Selected Day Tasks
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                _loadEvents(); // Refresh events when tasks change
                final dayTasks = _getTasksForDay(_selectedDay);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tasks for ${DateFormat('EEEE, MMMM d, y').format(_selectedDay)}',
                            style: AppTextStyles.subheading.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tasks List
                    Expanded(
                      child: dayTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks for this day',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTaskScreen(),
                                        ),
                                      );
                                      if (result == true) {
                                        setState(() {
                                          _loadEvents();
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.add),
                                    label: Text('Add Task'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[800],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: dayTasks.length,
                              itemBuilder: (context, index) {
                                final task = dayTasks[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: task.priority.priorityColor.withOpacity(0.2),
                                      child: Icon(
                                        task.isCompleted ? Icons.check : Icons.schedule,
                                        color: task.priority.priorityColor,
                                      ),
                                    ),
                                    title: Text(
                                      task.subject,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: task.isCompleted 
                                            ? TextDecoration.lineThrough 
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (task.notes.isNotEmpty)
                                          Text(
                                            task.notes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              decoration: task.isCompleted 
                                                  ? TextDecoration.lineThrough 
                                                  : null,
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: Colors.blue[800]),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('h:mm a').format(task.dateTime),
                                              style: TextStyle(
                                                color: Colors.blue[800],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.timer, size: 14, color: Colors.orange[800]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${task.duration} min',
                                              style: TextStyle(
                                                color: Colors.orange[800],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: task.priority.priorityColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                task.priority.priorityText,
                                                style: TextStyle(
                                                  color: task.priority.priorityColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: task.isCompleted
                                        ? Icon(Icons.check_circle, color: Colors.green)
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.play_circle, color: Colors.green[600]),
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => TaskCompletionScreen(task: task),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    setState(() {
                                                      _loadEvents();
                                                    });
                                                  }
                                                },
                                                tooltip: 'Complete Task',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.edit, color: Colors.blue[600]),
                                                onPressed: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AddTaskScreen(task: task),
                                                    ),
                                                  );
                                                  setState(() {
                                                    _loadEvents();
                                                  });
                                                },
                                                tooltip: 'Edit Task',
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(),
            ),
          );
          if (result == true) {
            setState(() {
              _loadEvents();
            });
          }
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Task',
      ),
    );
  }
} 