import 'package:flutter/material.dart';
import 'goal_service.dart';
import '../ads/ad_service.dart';
import '../profile/profile_service.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final GoalService _goalService = GoalService();
  ProfileService _profileService = ProfileService();
  bool _isPremium = false;

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
              onPressed: () async {
                await _profileService.upgradeToPremium();
                await _loadPremiumStatus();
                Navigator.pop(context);
                // Navigate to profile screen after upgrading
                Navigator.of(context).pushReplacementNamed('/profile');
              },
              child: const Text('Go Premium (Simulated)'),
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
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, userSnapshot) {
        return FutureBuilder(
          future: Future.wait([
            Future.value(userSnapshot.data),
            _profileService.getProfile(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final user = snapshot.data?[0] as User?;
            final profile = snapshot.data?[1] as Map<String, dynamic>?;
            final isVerified =
                user != null &&
                user.emailVerified &&
                user.email == profile?['email'];
            return Scaffold(
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'GoalTracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.flag),
                      title: Text('Goals'),
                      onTap: () {
                        Navigator.pop(context);
                        // Already on Goals
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.bar_chart),
                      title: Text('Analytics'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AnalyticsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),
              ),
              appBar: AppBar(
                title: const Text('Your Goals'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Help',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('How to Use'),
                          content: const Text(
                            'Tap the + button to add a new goal. Tap on a goal to expand and see subgoals. Check off subgoals as you complete them.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (!isVerified)
                    Card(
                      color: Colors.orange[50],
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your email ( ${user?.email}) is not verified. Please verify your email by ( ${profile?['email']}) or check span to unlock all features. If done, reflesh',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                const gmailUrl = 'https://mail.google.com';
                                final uri = Uri.parse(gmailUrl);
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error opening Gmail: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open Gmail'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (user != null) {
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
                                }
                              },
                              icon: const Icon(Icons.email),
                              label: const Text('Resend Verification Email'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (user != null) {
                                  await user.reload();
                                  if (context.mounted) {
                                    // Triggers StreamBuilder to rebuild
                                    (context as Element).markNeedsBuild();
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Status'),
                            ),
                          ],
                        ),
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
                                userEmail: user?.email ?? '',
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
                              child: ExpansionTile(
                                title: Text(
                                  goal['title'] ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                            userEmail: user?.email ?? '',
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
                                        'From: ${(goal['fromDate'] as Timestamp?)?.toDate()?.toLocal()?.toString().split(' ')[0] ?? ''}',
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
                                        'To: ${(goal['toDate'] as Timestamp?)?.toDate()?.toLocal()?.toString().split(' ')[0] ?? ''}',
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
                                              'From: ${((sg['fromDate'] as Timestamp?)?.toDate()?.toLocal()?.toString().split(' ')[0]) ?? ''}',
                                            ),
                                          if (sg['toDate'] != null)
                                            Text(
                                              'To: ${((sg['toDate'] as Timestamp?)?.toDate()?.toLocal()?.toString().split(' ')[0]) ?? ''}',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    title: const Text('Add subgoal'),
                                    leading: const Icon(Icons.add),
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
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Subgoal Title',
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
                                                          if (picked != null)
                                                            setState(
                                                              () =>
                                                                  subFromDate =
                                                                      picked,
                                                            );
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
                                                          if (picked != null)
                                                            setState(
                                                              () => subToDate =
                                                                  picked,
                                                            );
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
