import 'package:flutter/material.dart';
import 'goal_service.dart';
import '../ads/ad_service.dart';
import '../profile/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../settings/theme_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final GoalService _goalService = GoalService();
  final ProfileService _profileService = ProfileService();
  bool _isPremium = false;
  String _currentTemplate = 'Elegant Purple';

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  DateTime? _subgoalFromDate;
  DateTime? _subgoalToDate;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await ThemeService.getCurrentTemplate();
    setState(() {
      _currentTemplate = template;
    });
  }

  Future<void> _loadPremiumStatus() async {
    final profile = await _profileService.getProfile();
    setState(() {
      _isPremium = profile?['premium'] ?? false;
    });
  }

  void _showAddGoalDialog(int currentGoalCount) async {
    final user = FirebaseAuth.instance.currentUser;
    final profile = await _profileService.getProfile();
    final isVerified =
        user != null && user.emailVerified && user.email == profile?['email'];
    if (!isVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text('Please verify your email before adding a goal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!_isPremium && currentGoalCount >= 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text(
            'Free users can only have 3 active goals. Upgrade to premium for unlimited goals.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog first
                Navigator.of(
                  context,
                ).pushReplacementNamed('/profile'); // Redirect to profile page
              },
              child: const Text('Go Premium'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    hintText: 'Enter goal title',
                    hintStyle: TextStyle(color: Colors.black54),
                    prefixIcon: Icon(Icons.flag, color: Colors.black),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    hintText: 'Enter description',
                    hintStyle: TextStyle(color: Colors.black54),
                    prefixIcon: Icon(Icons.description, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fromDate == null
                            ? 'From date'
                            : 'From:  [32m${_fromDate!.toLocal().toString().split(' ')[0]} [0m',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fromDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _fromDate = picked);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _toDate == null
                            ? 'To date'
                            : 'To:  [32m${_toDate!.toLocal().toString().split(' ')[0]} [0m',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _toDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _toDate = picked);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _descController.clear();
                _fromDate = null;
                _toDate = null;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _titleController.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        print('Add button pressed');
                        await _goalService.addGoal(
                          _titleController.text,
                          _descController.text,
                          fromDate: _fromDate,
                          toDate: _toDate,
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          await _goalService.sendGoalEmailWithEmailJS(
                            userEmail: user.email!,
                            subject: 'Goal Added',
                            message:
                                'You have added a new goal: ${_titleController.text}\nDescription: ${_descController.text}',
                          );
                        }
                        print('Goal added');
                      } catch (e) {
                        print('Error adding goal: $e');
                      } finally {
                        print('Closing dialog');
                        _titleController.clear();
                        _descController.clear();
                        _fromDate = null;
                        _toDate = null;
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          print('Cannot pop context');
                        }
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateData = ThemeService.getTemplateData(_currentTemplate);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }
        return StreamBuilder<bool>(
          stream: Stream.value(user.emailVerified),
          builder: (context, emailSnapshot) {
            if (emailSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final isEmailVerified = emailSnapshot.data ?? false;
            return Scaffold(
              backgroundColor: templateData['backgroundColor'],
              body: Column(
                children: [
                  if (!isEmailVerified)
                    Container(
                      width: double.infinity,
                      color: Colors.orange,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Please verify your email to add goals',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await user.sendEmailVerification();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Verification email resent!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.email),
                                label: const Text('Resend Verification Email'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await user.reload();
                                  if (context.mounted) {
                                    // Triggers StreamBuilder to rebuild
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Status'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: StreamBuilder(
                      stream: _goalService.getGoals(),
                      builder: (context, snapshot) {
                        print(
                          'StreamBuilder snapshot: hasData= [32m${snapshot.hasData} [0m, docs= [32m${snapshot.data?.docs.length} [0m, error= [31m${snapshot.error} [0m',
                        );
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData ||
                            (snapshot.data?.docs.isEmpty ?? true)) {
                          return const Center(
                            child: Text('No goals yet. Add one!'),
                          );
                        }
                        final goals = snapshot.data!.docs;
                        goals.sort((a, b) {
                          final aTime = a['createdAt'] ?? Timestamp(0, 0);
                          final bTime = b['createdAt'] ?? Timestamp(0, 0);
                          return (bTime as Timestamp).compareTo(
                            aTime as Timestamp,
                          );
                        });
                        for (final doc in goals) {
                          final goal = doc.data() as Map<String, dynamic>;
                          final toDate = (goal['toDate'] as Timestamp?)
                              ?.toDate();
                          final status = goal['status'] ?? 'in_progress';
                          if (toDate != null && status != 'completed') {
                            final now = DateTime.now();
                            final diff = toDate.difference(now).inHours;
                            if (diff > 0 && diff <= 24) {
                              _goalService.sendGoalEmailWithEmailJS(
                                userEmail: user.email ?? '',
                                subject: 'Goal Deadline Approaching',
                                message:
                                    'Your goal "${goal['title']}" deadline is in less than 24 hours! Don\'t forget to complete it.',
                              );
                            }
                          }
                        }
                        return ListView.builder(
                          itemCount: goals.length,
                          itemBuilder: (context, i) {
                            final goal =
                                goals[i].data() as Map<String, dynamic>;
                            final subgoals = (goal['subgoals'] as List?) ?? [];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: templateData['cardColor'],
                              elevation: 4,
                              child: ExpansionTile(
                                title: Text(
                                  goal['title'] ?? '',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: templateData['primaryColor'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      value: goal['status'] ?? 'in_progress',
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'in_progress',
                                          child: Text('In Progress'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'completed',
                                          child: Text('Completed'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'canceled',
                                          child: Text('Canceled'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          _goalService.updateGoal(
                                            goals[i].id,
                                            status: value,
                                          );
                                          _goalService.sendGoalEmailWithEmailJS(
                                            userEmail: user.email ?? '',
                                            subject: 'Goal Status Updated',
                                            message:
                                                'Your goal "${goal['title']}" status is now: $value.',
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete goal',
                                      onPressed: () =>
                                          _goalService.deleteGoal(goals[i].id),
                                    ),
                                  ],
                                ),
                                children: [
                                  if ((goal['description'] ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 4,
                                      ),
                                      child: Text(goal['description'] ?? ''),
                                    ),
                                  if (goal['fromDate'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 2,
                                      ),
                                      child: Text(
                                        'From: ${(goal['fromDate'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0] ?? ''}',
                                      ),
                                    ),
                                  if (goal['toDate'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        'To: ${(goal['toDate'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0] ?? ''}',
                                      ),
                                    ),
                                  ...subgoals.map<Widget>(
                                    (sg) => ListTile(
                                      title: Text(sg['title'] ?? ''),
                                      leading: Checkbox(
                                        value: sg['completed'] ?? false,
                                        onChanged: (val) {
                                          final updated =
                                              List<Map<String, dynamic>>.from(
                                                subgoals,
                                              );
                                          updated[subgoals.indexOf(
                                                sg,
                                              )]['completed'] =
                                              val;
                                          _goalService.updateGoal(
                                            goals[i].id,
                                            subgoals: updated,
                                          );
                                        },
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (sg['fromDate'] != null)
                                            Text(
                                              'From: ${((sg['fromDate'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0]) ?? ''}',
                                            ),
                                          if (sg['toDate'] != null)
                                            Text(
                                              'To: ${((sg['toDate'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0]) ?? ''}',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text(
                                      'Add subgoal',
                                      style: TextStyle(
                                        color: templateData['primaryColor'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    leading: Icon(
                                      Icons.add,
                                      color: templateData['primaryColor'],
                                    ),
                                    onTap: () async {
                                      final controller =
                                          TextEditingController();
                                      DateTime? subFromDate;
                                      DateTime? subToDate;
                                      await showDialog(
                                        context: context,
                                        builder: (context) => StatefulBuilder(
                                          builder: (context, setState) => AlertDialog(
                                            title: const Text('Add Subgoal'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: controller,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Subgoal Title',
                                                          labelStyle: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                          hintText:
                                                              'Enter subgoal title',
                                                          hintStyle: TextStyle(
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subFromDate == null
                                                              ? 'From date'
                                                              : 'From: ${subFromDate?.toLocal().toString().split(' ')[0] ?? ''}',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          final picked =
                                                              await showDatePicker(
                                                                context:
                                                                    context,
                                                                initialDate:
                                                                    subFromDate ??
                                                                    DateTime.now(),
                                                                firstDate:
                                                                    DateTime(
                                                                      2000,
                                                                    ),
                                                                lastDate:
                                                                    DateTime(
                                                                      2100,
                                                                    ),
                                                              );
                                                          if (picked != null) {
                                                            setState(
                                                              () =>
                                                                  subFromDate =
                                                                      picked,
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Select',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subToDate == null
                                                              ? 'To date'
                                                              : 'To: ${subToDate?.toLocal().toString().split(' ')[0] ?? ''}',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          final picked =
                                                              await showDatePicker(
                                                                context:
                                                                    context,
                                                                initialDate:
                                                                    subToDate ??
                                                                    DateTime.now(),
                                                                firstDate:
                                                                    DateTime(
                                                                      2000,
                                                                    ),
                                                                lastDate:
                                                                    DateTime(
                                                                      2100,
                                                                    ),
                                                              );
                                                          if (picked != null) {
                                                            setState(
                                                              () => subToDate =
                                                                  picked,
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Select',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final updated =
                                                      List<
                                                          Map<String, dynamic>
                                                        >.from(subgoals)
                                                        ..add({
                                                          'title':
                                                              controller.text,
                                                          'completed': false,
                                                          if (subFromDate !=
                                                              null)
                                                            'fromDate':
                                                                subFromDate,
                                                          if (subToDate != null)
                                                            'toDate': subToDate,
                                                        });
                                                  await _goalService.updateGoal(
                                                    goals[i].id,
                                                    subgoals: updated,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
              floatingActionButton: StreamBuilder(
                stream: _goalService.getGoals(),
                builder: (context, snapshot) {
                  final currentGoalCount = snapshot.data?.docs.length ?? 0;
                  return FloatingActionButton(
                    onPressed: () => _showAddGoalDialog(currentGoalCount),
                    tooltip: 'Add new goal',
                    backgroundColor: templateData['primaryColor'],
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
