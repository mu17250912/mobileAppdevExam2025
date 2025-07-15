import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({Key? key}) : super(key: key);

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    _ManagerHomePage(),
    _ManagerJobsPage(),
    _ManagerProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF6A8DFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Refactor _ManagerHomePage for modern look
class _ManagerHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF6A8DFF),
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${user?.displayName ?? 'Manager'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Your dashboard', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats Cards
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('managerId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int total = 0, open = 0, assigned = 0, completed = 0;
                    if (snapshot.hasData) {
                      total = snapshot.data!.docs.length;
                      for (var doc in snapshot.data!.docs) {
                        final job = doc.data() as Map<String, dynamic>;
                        final status = (job['status'] ?? '').toString().toLowerCase();
                        if (status == 'open') open++;
                        else if (status == 'assigned') assigned++;
                        else if (status == 'completed') completed++;
                      }
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatCard(label: 'Total Jobs', value: total, icon: Icons.list_alt, color: Colors.blue),
                          _StatCard(label: 'Open', value: open, icon: Icons.work_outline, color: Colors.green),
                          _StatCard(label: 'Assigned', value: assigned, icon: Icons.assignment_ind, color: Colors.orange),
                          _StatCard(label: 'Completed', value: completed, icon: Icons.check_circle_outline, color: Colors.purple),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  ],
                ),
                const SizedBox(height: 32),
                // Recent Jobs
                const Text('Recent Jobs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('managerId', isEqualTo: user?.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error:  ${snapshot.error}'));
                    }
                    final jobs = snapshot.data?.docs ?? [];
                    if (jobs.isEmpty) {
                      return Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('No recent jobs.', style: TextStyle(color: Colors.grey)),
                        ],
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.work, color: Color(0xFF6A8DFF)),
                            title: Row(
                              children: [
                                Expanded(child: Text(job['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold))),
                                _statusBadge(job['status'] ?? ''),
                              ],
                            ),
                            subtitle: Text(job['status'] ?? 'No status'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerJobsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Jobs'),
        backgroundColor: const Color(0xFF6A8DFF),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('managerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error:  ${snapshot.error}'));
                }
                final jobs = snapshot.data?.docs ?? [];
                if (jobs.isEmpty) {
                  return const Center(child: Text('No jobs found.'));
                }
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;
                    final jobId = jobs[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(job['title'] ?? 'Untitled')),
                            _statusBadge(job['status'] ?? ''),
                          ],
                        ),
                        subtitle: Text(job['status'] ?? 'No status'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.group, color: Colors.blue),
                              tooltip: 'View Applicants',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => _ApplicantsDialog(jobId: jobId),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => _EditJobDialog(jobId: jobId, job: job),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Job'),
                                    content: const Text('Are you sure you want to delete this job? This cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Job deleted.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: user == null ? null : FloatingActionButton(
        onPressed: () async {
          // Premium check and job count limit
          final isPremium = Provider.of<UserProvider>(context, listen: false).isPremium;
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final jobsThisMonth = await FirebaseFirestore.instance
              .collection('jobs')
              .where('managerId', isEqualTo: user.uid)
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
              .get();
          if (!isPremium && jobsThisMonth.docs.length >= 3) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Premium Feature'),
                content: const Text('You have reached your free limit of 3 job posts this month. Subscribe to post more jobs.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/subscribe');
                    },
                    child: const Text('Subscribe'),
                  ),
                ],
              ),
            );
            return;
          }
          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) => _CreateJobDialog(),
          );
          if (result != null) {
            await FirebaseFirestore.instance.collection('jobs').add({
              'title': result['title'],
              'description': result['description'],
              'managerId': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'open',
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job created!')),
            );
          }
        },
        backgroundColor: const Color(0xFF6A8DFF),
        child: const Icon(Icons.add),
        tooltip: 'Create Job',
      ),
    );
  }
}

class _CreateJobDialog extends StatefulWidget {
  @override
  State<_CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<_CreateJobDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _location;
  DateTime? _date;
  TimeOfDay? _time;
  String? _payRate;
  String? _jobType;
  int _numCleaners = 1;
  List<String> _customQuestions = [];
  List<TextEditingController> _questionControllers = [];
  List<String> _attachments = [];
  String? _specialInstructions;
  DateTime? _applicationDeadline;
  bool _isRecurring = false;
  bool _showPreview = false;

  final List<String> _jobTypes = [
    'Hotel Housekeeping',
    'Industrial Cleaning',
    'Office Cleaning',
    'Post-Construction',
    'Outdoor Sweeping',
    'Other',
  ];

  @override
  void dispose() {
    for (var c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCustomQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeCustomQuestion(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _applicationDeadline = picked);
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preview Job'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _previewRow('Title', _title ?? ''),
                _previewRow('Description', _description ?? ''),
                _previewRow('Location', _location ?? ''),
                _previewRow('Date', _date != null ? _date!.toLocal().toString().split(' ')[0] : ''),
                _previewRow('Time', _time != null ? _time!.format(context) : ''),
                _previewRow('Pay Rate', _payRate ?? ''),
                _previewRow('Job Type', _jobType ?? ''),
                _previewRow('Number of Cleaners', _numCleaners.toString()),
                if (_customQuestions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Custom Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._customQuestions.map((q) => Text('- $q')),
                    ],
                  ),
                _previewRow('Special Instructions', _specialInstructions ?? ''),
                _previewRow('Application Deadline', _applicationDeadline != null ? _applicationDeadline!.toLocal().toString().split(' ')[0] : ''),
                _previewRow('Recurring', _isRecurring ? 'Yes' : 'No'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                // Save job to Firestore
                await FirebaseFirestore.instance.collection('jobs').add({
                  'title': _title,
                  'description': _description,
                  'location': _location,
                  'date': _date,
                  'time': _time != null ? _time!.format(context) : null,
                  'payRate': _payRate,
                  'jobType': _jobType,
                  'numCleaners': _numCleaners,
                  'customQuestions': _customQuestions,
                  'specialInstructions': _specialInstructions,
                  'applicationDeadline': _applicationDeadline,
                  'isRecurring': _isRecurring,
                  'managerId': user.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'open',
                });
                Navigator.of(context).pop(); // Close preview
                Navigator.of(context).pop(); // Close create dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job created!')),
                );
              },
              child: const Text('Confirm & Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _hidePreviewDialog() {
    setState(() => _showPreview = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Job'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
                onSaved: (v) => _title = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
                onSaved: (v) => _description = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (v) => _location = v,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_date == null ? 'No date chosen' : 'Date: ${_date!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_time == null ? 'No time chosen' : 'Time: ${_time!.format(context)}'),
                  ),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('Pick Time'),
                  ),
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Pay Rate (e.g. per hour)'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _payRate = v,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Job Type'),
                items: _jobTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (v) => setState(() => _jobType = v),
                onSaved: (v) => _jobType = v,
              ),
              Row(
                children: [
                  const Text('Number of Cleaners:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _numCleaners.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_numCleaners',
                      onChanged: (v) => setState(() => _numCleaners = v.toInt()),
                    ),
                  ),
                  Text('$_numCleaners'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Custom Questions:'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCustomQuestion,
                  ),
                ],
              ),
              ..._questionControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(labelText: 'Question ${idx + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeCustomQuestion(idx),
                    ),
                  ],
                );
              }).toList(),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Special Instructions'),
                onSaved: (v) => _specialInstructions = v,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_applicationDeadline == null ? 'No deadline' : 'Deadline: ${_applicationDeadline!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: _pickDeadline,
                    child: const Text('Pick Deadline'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Recurring Job?'),
                  Switch(
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                  ),
                ],
              ),
              // Attachments and preview can be added here (file picker placeholder)
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Collect custom questions
                    _customQuestions = _questionControllers.map((c) => c.text).where((q) => q.isNotEmpty).toList();
                    _showPreviewDialog();
                  }
                },
                child: const Text('Preview'),
              ),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              // Collect custom questions
              _customQuestions = _questionControllers.map((c) => c.text).where((q) => q.isNotEmpty).toList();
              if (_showPreview) {
                _hidePreviewDialog();
              } else {
                _showPreviewDialog();
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
      // Preview Dialog
      insetPadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.all(16),
      // Show preview if requested
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _EditJobDialog extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> job;
  const _EditJobDialog({required this.jobId, required this.job});
  @override
  State<_EditJobDialog> createState() => _EditJobDialogState();
}

class _EditJobDialogState extends State<_EditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  String? _location;
  DateTime? _date;
  TimeOfDay? _time;
  String? _payRate;
  String? _jobType;
  int _numCleaners = 1;
  List<String> _customQuestions = [];
  List<TextEditingController> _questionControllers = [];
  String? _specialInstructions;
  DateTime? _applicationDeadline;
  bool _isRecurring = false;

  final List<String> _jobTypes = [
    'Hotel Housekeeping',
    'Industrial Cleaning',
    'Office Cleaning',
    'Post-Construction',
    'Outdoor Sweeping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _title = job['title'] ?? '';
    _description = job['description'] ?? '';
    _location = job['location'] ?? '';
    _payRate = job['payRate'] ?? '';
    _jobType = job['jobType'] ?? null;
    _numCleaners = job['numCleaners'] ?? 1;
    _specialInstructions = job['specialInstructions'] ?? '';
    _isRecurring = job['isRecurring'] ?? false;
    _customQuestions = (job['customQuestions'] as List?)?.cast<String>() ?? [];
    _questionControllers = _customQuestions.map((q) => TextEditingController(text: q)).toList();
    // Parse date
    if (job['date'] != null && job['date'] is Timestamp) {
      _date = (job['date'] as Timestamp).toDate();
    } else if (job['date'] is DateTime) {
      _date = job['date'];
    }
    // Parse time
    if (job['time'] != null && job['time'] is String && job['time'].contains(':')) {
      final parts = job['time'].split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      _time = TimeOfDay(hour: hour, minute: minute);
    }
    // Parse deadline
    if (job['applicationDeadline'] != null && job['applicationDeadline'] is Timestamp) {
      _applicationDeadline = (job['applicationDeadline'] as Timestamp).toDate();
    } else if (job['applicationDeadline'] is DateTime) {
      _applicationDeadline = job['applicationDeadline'];
    }
  }

  @override
  void dispose() {
    for (var c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCustomQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeCustomQuestion(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _applicationDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _applicationDeadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Job'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
                onChanged: (v) => _title = v,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a description' : null,
                onChanged: (v) => _description = v,
              ),
              TextFormField(
                initialValue: _location,
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (v) => _location = v,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_date == null ? 'No date chosen' : 'Date: ${_date!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_time == null ? 'No time chosen' : 'Time: ${_time!.format(context)}'),
                  ),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('Pick Time'),
                  ),
                ],
              ),
              TextFormField(
                initialValue: _payRate,
                decoration: const InputDecoration(labelText: 'Pay Rate (e.g. per hour)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _payRate = v,
              ),
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(labelText: 'Job Type'),
                items: _jobTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (v) => setState(() => _jobType = v),
              ),
              Row(
                children: [
                  const Text('Number of Cleaners:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _numCleaners.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_numCleaners',
                      onChanged: (v) => setState(() => _numCleaners = v.toInt()),
                    ),
                  ),
                  Text('$_numCleaners'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Custom Questions:'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCustomQuestion,
                  ),
                ],
              ),
              ..._questionControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(labelText: 'Question ${idx + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeCustomQuestion(idx),
                    ),
                  ],
                );
              }).toList(),
              TextFormField(
                initialValue: _specialInstructions,
                decoration: const InputDecoration(labelText: 'Special Instructions'),
                onChanged: (v) => _specialInstructions = v,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_applicationDeadline == null ? 'No deadline' : 'Deadline: ${_applicationDeadline!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: _pickDeadline,
                    child: const Text('Pick Deadline'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Recurring Job?'),
                  Switch(
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                  ),
                ],
              ),
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // Collect custom questions
              _customQuestions = _questionControllers.map((c) => c.text).where((q) => q.isNotEmpty).toList();
              await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
                'title': _title,
                'description': _description,
                'location': _location,
                'date': _date,
                'time': _time != null ? _time!.format(context) : null,
                'payRate': _payRate,
                'jobType': _jobType,
                'numCleaners': _numCleaners,
                'customQuestions': _customQuestions,
                'specialInstructions': _specialInstructions,
                'applicationDeadline': _applicationDeadline,
                'isRecurring': _isRecurring,
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job updated!')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ManagerProfilePage extends StatefulWidget {
  @override
  State<_ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<_ManagerProfilePage> {
  bool _loading = false;
  String? _error;

  void _showEditProfileDialog(Map<String, dynamic> data, User user) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name'] ?? user.displayName ?? '');
    final emailController = TextEditingController(text: data['email'] ?? user.email ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    bool loading = false;
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(error!, style: const TextStyle(color: Colors.red)),
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
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'phone': phoneController.text.trim(),
                            });
                            await user.updateDisplayName(nameController.text.trim());
                            await user.updateEmail(emailController.text.trim());
                            if (mounted) Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                            setState(() {});
                          } on FirebaseAuthException catch (e) {
                            setState(() => error = e.message);
                          } catch (e) {
                            setState(() => error = 'Failed to update profile.');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  void _showChangePasswordDialog(User user) async {
    final _formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool loading = false;
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (v) => v == null || v.isEmpty ? 'Enter your current password' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPasswordController.text.trim(),
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newPasswordController.text.trim());
                            if (mounted) Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
                          } on FirebaseAuthException catch (e) {
                            setState(() => error = e.message);
                          } catch (e) {
                            setState(() => error = 'Failed to change password.');
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  // TODO: Add profile picture upload, delete account, and show additional info

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF6A8DFF),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error:  ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found.'));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name'] ?? user.displayName ?? 'Manager';
                final email = data['email'] ?? user.email ?? '';
                final phone = data['phone'] ?? '';
                final createdAt = (data['createdAt'] != null && data['createdAt'] is Timestamp)
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                String formattedDate = createdAt != null
                    ? '${_monthName(createdAt.month)} ${createdAt.day}, ${createdAt.year}'
                    : '';
                return Center(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFF6A8DFF),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                if (context.watch<UserProvider>().isPremium)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.star, size: 16, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(email, style: TextStyle(color: Colors.grey[700])),
                            Text(phone, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            if (formattedDate.isNotEmpty)
                              Text('Joined: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A8DFF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  onPressed: () => _showEditProfileDialog(data, user),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.lock),
                                  label: const Text('Change Password'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A8DFF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  onPressed: () => _showChangePasswordDialog(user),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!context.watch<UserProvider>().isPremium)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.star),
                                  label: const Text('Subscribe for Premium'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/subscribe');
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class _ApplicantsDialog extends StatelessWidget {
  final String jobId;
  const _ApplicantsDialog({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, jobSnapshot) {
        final jobData = jobSnapshot.data?.data() as Map<String, dynamic>?;
        final assignedCleanerId = jobData?['assignedCleanerId'];
        return AlertDialog(
          title: const Text('Applicants'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .doc(jobId)
                .collection('applicants')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Error:  ${snapshot.error}');
              }
              final applicants = snapshot.data?.docs ?? [];
              if (applicants.isEmpty) {
                return const Text('No applicants yet.');
              }
              return SizedBox(
                width: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final data = applicants[index].data() as Map<String, dynamic>;
                    final applicantId = applicants[index].id;
                    final status = (data['status'] ?? 'pending').toString().toLowerCase();
                    Color statusColor;
                    String statusLabel;
                    IconData? statusIcon;
                    switch (status) {
                      case 'accepted':
                        statusColor = Colors.green;
                        statusLabel = 'Accepted';
                        statusIcon = Icons.check_circle;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        statusLabel = 'Rejected';
                        statusIcon = Icons.cancel;
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusLabel = 'Pending';
                        statusIcon = Icons.hourglass_empty;
                    }
                    final isAssigned = assignedCleanerId == applicantId;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.person, color: statusColor),
                        title: Row(
                          children: [
                            Expanded(child: Text(data['name'] ?? 'No name')),
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 4),
                            Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (isAssigned)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Assigned', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Color(0xFF6A8DFF)),
                              tooltip: 'View Profile',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => _ApplicantProfileDialog(applicantId: applicantId),
                                );
                              },
                            ),
                            if (status == 'pending') ...[
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Accept',
                                onPressed: () async {
                                  // Accept applicant
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobId)
                                      .collection('applicants')
                                      .doc(applicantId)
                                      .update({'status': 'accepted'});
                                  // Assign job to this cleaner
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobId)
                                      .update({
                                        'cleanerId': applicantId,
                                        'cleanerName': data['name'] ?? '',
                                        'status': 'assigned',
                                      });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Reject',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(jobId)
                                      .collection('applicants')
                                      .doc(applicantId)
                                      .update({'status': 'rejected'});
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ApplicantProfileDialog extends StatelessWidget {
  final String applicantId;
  const _ApplicantProfileDialog({required this.applicantId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(applicantId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const AlertDialog(
            title: Text('Profile'),
            content: Text('Failed to load profile.'),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phone'] ?? '';
        final createdAt = (data['createdAt'] != null && data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
        String formattedDate = createdAt != null
            ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
            : '';
        return AlertDialog(
          title: const Text('Applicant Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF6A8DFF),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(color: Colors.black54)),
                      if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: Colors.black54)),
                      if (formattedDate.isNotEmpty)
                        Text('Joined: $formattedDate', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data['resumeUrl'] != null && data['resumeFileName'] != null)
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 18, color: Color(0xFF6A8DFF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(data['resumeUrl'])),
                        child: Text(
                          data['resumeFileName'],
                          style: const TextStyle(
                            color: Color(0xFF6A8DFF),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Helper widget for status badge
Widget _statusBadge(String status) {
  Color color;
  String label = status;
  switch (status.toLowerCase()) {
    case 'open':
      color = Colors.green;
      label = 'Open';
      break;
    case 'assigned':
      color = Colors.orange;
      label = 'Assigned';
      break;
    case 'completed':
      color = Colors.purple;
      label = 'Completed';
      break;
    default:
      color = Colors.grey;
      label = status;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
} 