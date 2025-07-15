import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_upgrade_dialog.dart';
import 'premium_features_summary.dart';
import 'notification_service.dart';

class SmartRemindersScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const SmartRemindersScreen({super.key, this.onRequirePremium});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _reminders = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _selectedCategory = 'Bill';
  String _selectedPriority = 'Medium';
  bool _isRecurring = false;
  String _recurrenceType = 'Monthly';
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();
  final NotificationService _notificationService = NotificationService();
  bool _smartRemindersUnlocked = false;

  final List<String> _categories = [
    'Bill',
    'Subscription',
    'Insurance',
    'Loan Payment',
    'Credit Card',
    'Rent',
    'Utility',
    'Tax',
    'Other'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _recurrenceTypes = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders();
    _checkSmartRemindersUnlocked();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      print('Notification service initialized');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: user.uid)
            .get();

        final reminders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'amount': data['amount'] ?? 0.0,
            'description': data['description'] ?? '',
            'dueDate': data['dueDate'] as Timestamp?,
            'dueTime': data['dueTime'] ?? '09:00',
            'category': data['category'] ?? 'Bill',
            'priority': data['priority'] ?? 'Medium',
            'isRecurring': data['isRecurring'] ?? false,
            'recurrenceType': data['recurrenceType'] ?? 'Monthly',
            'isCompleted': data['isCompleted'] ?? false,
            'createdAt': data['createdAt'] as Timestamp?,
          };
        }).toList();

        // Sort in memory by due date
        reminders.sort((a, b) {
          final aDate = a['dueDate'] as Timestamp?;
          final bDate = b['dueDate'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });

        setState(() {
          _reminders = reminders;
        });
        
        print('Loaded ${reminders.length} reminders');
      }
    } catch (e) {
      print('Error loading reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkIsPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['isPremium'] ?? false);
  }

  Future<void> _checkSmartRemindersUnlocked() async {
    final unlocked = await _premiumManager.isFeatureUnlocked('smartReminders');
    setState(() {
      _smartRemindersUnlocked = unlocked;
    });
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock Smart Reminders'),
        content: Text('This is a premium feature. Please pay to unlock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _premiumManager.unlockFeature('smartReminders');
              await _checkSmartRemindersUnlocked();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Smart Reminders unlocked!')),
              );
            },
            child: Text('Pay & Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder() async {
    if (!_smartRemindersUnlocked) {
      _showPaywall();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a due date', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create the reminder document
        final reminderRef = await FirebaseFirestore.instance.collection('reminders').add({
          'userId': user.uid,
          'title': _titleController.text.trim(),
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'description': _descriptionController.text.trim(),
          'dueDate': Timestamp.fromDate(_dueDate!),
          'dueTime': _dueTime?.format(context) ?? '09:00',
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'isRecurring': _isRecurring,
          'recurrenceType': _recurrenceType,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Schedule notification for the reminder
        try {
          final notificationId = reminderRef.id.hashCode;
          final dueDateTime = _dueDate!;
          
          // Schedule notification 1 day before due date
          await _notificationService.scheduleReminderWithAdvance(
            id: notificationId,
            title: 'Reminder: ${_titleController.text.trim()}',
            body: 'Due tomorrow: ${_descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : _titleController.text.trim()}',
            dueDate: dueDateTime,
            advanceDays: 1,
            payload: reminderRef.id,
          );

          // Schedule notification on the due date
          await _notificationService.scheduleReminderNotification(
            id: notificationId + 1,
            title: 'Due Today: ${_titleController.text.trim()}',
            body: 'Your reminder is due today! ${_descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : ''}',
            scheduledDate: dueDateTime,
            payload: reminderRef.id,
          );

          print('Scheduled notifications for reminder: ${reminderRef.id}');
        } catch (e) {
          print('Error scheduling notification: $e');
          // Don't fail the reminder creation if notification fails
        }

        _titleController.clear();
        _amountController.clear();
        _descriptionController.clear();
        _dueDate = null;
        _dueTime = null;
        _selectedCategory = 'Bill';
        _selectedPriority = 'Medium';
        _isRecurring = false;
        _recurrenceType = 'Monthly';

        await _loadReminders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder added successfully!', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add reminder: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReminder(String reminderId, bool isCompleted) async {
    try {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .update({'isCompleted': !isCompleted});

      // Cancel notifications if reminder is completed
      if (!isCompleted) {
        final notificationId = reminderId.hashCode;
        await _notificationService.cancelNotification(notificationId);
        await _notificationService.cancelNotification(notificationId + 1);
        print('Cancelled notifications for completed reminder: $reminderId');
      }

      await _loadReminders();
    } catch (e) {
      print('Error toggling reminder: $e');
    }
  }

  Future<void> _deleteReminder(String reminderId) async {
    try {
      // Cancel notifications for the reminder
      final notificationId = reminderId.hashCode;
      await _notificationService.cancelNotification(notificationId);
      await _notificationService.cancelNotification(notificationId + 1);
      print('Cancelled notifications for deleted reminder: $reminderId');

      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminderId)
          .delete();

      await _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder deleted successfully!', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete reminder: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcomingReminders = _reminders.where((r) {
      final dueDate = r['dueDate'] as Timestamp?;
      return dueDate != null && 
             dueDate.toDate().isAfter(now) && 
             !(r['isCompleted'] as bool);
    }).toList();
    
    final overdueReminders = _reminders.where((r) {
      final dueDate = r['dueDate'] as Timestamp?;
      return dueDate != null && 
             dueDate.toDate().isBefore(now) && 
             !(r['isCompleted'] as bool);
    }).toList();
    
    final completedReminders = _reminders.where((r) => r['isCompleted'] as bool).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Smart Reminders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Debug button for testing
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showDebugMenu(),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _loadReminders(),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showAddReminderDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Upcoming',
                              upcomingReminders.length.toString(),
                              Icons.schedule,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Overdue',
                              overdueReminders.length.toString(),
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Completed',
                              completedReminders.length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Overdue Reminders
                      if (overdueReminders.isNotEmpty) ...[
                        _buildSectionHeader('Overdue', Colors.red),
                        const SizedBox(height: 12),
                        ...overdueReminders.map((reminder) => _buildReminderCard(reminder, true)),
                        const SizedBox(height: 24),
                      ],

                      // Upcoming Reminders
                      if (upcomingReminders.isNotEmpty) ...[
                        _buildSectionHeader('Upcoming', Colors.blue),
                        const SizedBox(height: 12),
                        ...upcomingReminders.map((reminder) => _buildReminderCard(reminder, false)),
                        const SizedBox(height: 24),
                      ],

                      // Completed Reminders
                      if (completedReminders.isNotEmpty) ...[
                        _buildSectionHeader('Completed', Colors.green),
                        const SizedBox(height: 12),
                        ...completedReminders.map((reminder) => _buildReminderCard(reminder, false)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reminders Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up smart reminders to never miss important payments',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Reminder'),
            onPressed: () => _showAddReminderDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, bool isOverdue) {
    final dueDate = reminder['dueDate'] as Timestamp?;
    final daysLeft = dueDate != null 
        ? dueDate.toDate().difference(DateTime.now()).inDays 
        : 0;
    final isCompleted = reminder['isCompleted'] as bool;
    final priority = reminder['priority'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.withOpacity(0.3)
              : _getPriorityColor(priority).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) => _toggleReminder(reminder['id'], isCompleted),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          reminder['title'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCompleted 
                ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                : Theme.of(context).textTheme.titleMedium?.color,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder['description'].isNotEmpty)
              Text(
                reminder['description'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(reminder['category']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder['category'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getCategoryColor(reminder['category']),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  dueDate != null 
                      ? '${dueDate.toDate().day}/${dueDate.toDate().month}/${dueDate.toDate().year}'
                      : 'No date',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (reminder['amount'] > 0) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reminder['amount'].toStringAsFixed(0)} FRW',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Overdue by ${daysLeft.abs()} days',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteReminder(reminder['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Reminder'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add New Reminder',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (FRW)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPriority = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      _dueDate != null 
                          ? 'Due Date: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Select Due Date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() => _dueDate = date);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      _dueTime != null 
                          ? 'Due Time: ${_dueTime!.format(context)}'
                          : 'Select Due Time (Optional)',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _dueTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Recurring Reminder'),
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value);
                    },
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _recurrenceType,
                      decoration: const InputDecoration(
                        labelText: 'Recurrence',
                        border: OutlineInputBorder(),
                      ),
                      items: _recurrenceTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _recurrenceType = value!);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
                _addReminder();
              },
              child: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bill':
        return Colors.blue;
      case 'Subscription':
        return Colors.green;
      case 'Insurance':
        return Colors.orange;
      case 'Loan Payment':
        return Colors.red;
      case 'Credit Card':
        return Colors.purple;
      case 'Rent':
        return Colors.teal;
      case 'Utility':
        return Colors.indigo;
      case 'Tax':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showDebugMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Tools', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add, color: Colors.green),
              title: Text('Create Test Reminder'),
              subtitle: Text('Add a sample reminder for testing'),
              onTap: () {
                Navigator.of(context).pop();
                _createTestReminder();
              },
            ),
            ListTile(
              leading: Icon(Icons.add, color: Colors.blue),
              title: Text('Create Test Reminder (Premium Check)'),
              subtitle: Text('Add reminder with premium validation'),
              onTap: () {
                Navigator.of(context).pop();
                _createTestReminderWithPremiumCheck();
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.orange),
              title: Text('Show Debug Info'),
              subtitle: Text('Display current state information'),
              onTap: () {
                Navigator.of(context).pop();
                _showDebugInfo();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Clear All Reminders'),
              subtitle: Text('Delete all reminders (use with caution)'),
              onTap: () {
                Navigator.of(context).pop();
                _clearAllReminders();
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.purple),
              title: Text('Test Notification'),
              subtitle: Text('Show a test notification immediately'),
              onTap: () {
                Navigator.of(context).pop();
                _testNotification();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('reminders').add({
        'userId': user.uid,
        'title': 'Test Reminder ${DateTime.now().millisecondsSinceEpoch}',
        'amount': 5000.0,
        'description': 'This is a test reminder created for debugging',
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'dueTime': '09:00',
        'category': 'Bill',
        'priority': 'Medium',
        'isRecurring': false,
        'recurrenceType': 'Monthly',
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test reminder created successfully!')),
      );
    } catch (e) {
      print('Error creating test reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test reminder: $e')),
      );
    }
  }

  Future<void> _createTestReminderWithPremiumCheck() async {
    if (!_smartRemindersUnlocked) {
      _showPaywall();
      return;
    }
    await _createTestReminder();
  }

  void _showDebugInfo() {
    final now = DateTime.now();
    final upcomingReminders = _reminders.where((r) {
      final dueDate = r['dueDate'] as Timestamp?;
      return dueDate != null && 
             dueDate.toDate().isAfter(now) && 
             !(r['isCompleted'] as bool);
    }).toList();
    
    final overdueReminders = _reminders.where((r) {
      final dueDate = r['dueDate'] as Timestamp?;
      return dueDate != null && 
             dueDate.toDate().isBefore(now) && 
             !(r['isCompleted'] as bool);
    }).toList();
    
    final completedReminders = _reminders.where((r) => r['isCompleted'] as bool).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Reminders: ${_reminders.length}'),
              Text('Upcoming: ${upcomingReminders.length}'),
              Text('Overdue: ${overdueReminders.length}'),
              Text('Completed: ${completedReminders.length}'),
              Text('Premium Unlocked: $_smartRemindersUnlocked'),
              const SizedBox(height: 16),
              Text('Reminder Details:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ..._reminders.take(5).map((reminder) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Title: ${reminder['title']}'),
                    Text('Due: ${reminder['dueDate'] != null ? (reminder['dueDate'] as Timestamp).toDate().toString() : 'No date'}'),
                    Text('Completed: ${reminder['isCompleted']}'),
                    const Divider(),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Reminders?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This will delete ALL reminders. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final batch = FirebaseFirestore.instance.batch();
          final reminders = await FirebaseFirestore.instance
              .collection('reminders')
              .where('userId', isEqualTo: user.uid)
              .get();
          
          for (final doc in reminders.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          await _loadReminders();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All reminders cleared!')),
          );
        }
      } catch (e) {
        print('Error clearing reminders: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing reminders: $e')),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showImmediateNotification(
        title: 'Test Reminder',
        body: 'This is a test notification from SmartBudget!',
        payload: 'test_notification',
      );
      
      // Show web notification if on web platform
      _notificationService.showWebNotification(
        context,
        'Test Reminder',
        'This is a test notification from SmartBudget!',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test notification sent!')),
      );
    } catch (e) {
      print('Error showing test notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error showing notification: $e')),
      );
    }
  }
} 