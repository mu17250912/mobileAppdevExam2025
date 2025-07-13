import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_details_screen.dart';
import 'featured_tasks_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_details_screen.dart'; // Added import for JobDetailsScreen
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> provinces = [
    'All',
    'Kigali',
    'Rubavu',
    'Musanze',
    'Huye',
    // Add more provinces as needed
  ];
  String selectedProvince = 'All';
  int _selectedIndex = 0;
  bool _darkMode = false;

  // Add a variable to store the profile image URL (for demonstration)
  String? _profileImageUrl;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildDashboard(),
      _buildCashoutTab(),
      _buildMyTasksTab(),
      _buildProfileTab(),
    ];
  }

  void _onNavTap(int index) {
    if (index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onDrawerTap(int index) {
    Navigator.pop(context);
    if (index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        // Removed location filter UI
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('is_active', isEqualTo: true)
                .where('slots_filled', isLessThan: 9999999) // placeholder, will filter below
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final tasks = snapshot.data?.docs ?? [];
              // Filter out tasks where slots_filled >= total_slots
              final availableTasks = tasks.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final slotsFilled = data['slots_filled'] ?? 0;
                final totalSlots = data['total_slots'] ?? 1;
                return slotsFilled < totalSlots;
              }).toList();
              if (availableTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableTasks.length,
                itemBuilder: (context, index) {
                  final task = availableTasks[index].data() as Map<String, dynamic>;
                  final title = (task['title'] ?? '').toString();
                  final description = (task['description'] ?? '').toString();
                  final salary = task['reward_per_task']?.toString() ?? '';
                  final postedAt = (task['postedAt'] ?? '').toString();
                  final imageUrl = task['imageUrl'] as String?;
                  final slotsFilled = task['slots_filled'] ?? 0;
                  final totalSlots = task['total_slots'] ?? 1;
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailsScreen(task: {
                            'title': title,
                            'description': description,
                            'salary': salary,
                            'postedAt': postedAt,
                          }),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Reward: RWF $salary',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green, fontSize: 16),
                                    ),
                                    if (int.tryParse(salary) != null && int.parse(salary) > 20)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Featured',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Completed: $slotsFilled / $totalSlots',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCashoutTab() {
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();
    bool _loading = false;
    
    Future<void> _processCashout() async {
      if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount < 1500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimum withdrawal is 1500 RWF (1000 + 500 fee)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _loading = true;
      });
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      setState(() {
        _loading = false;
      });
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 10),
                const Text('Cashout Requested'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: RWF ${amount.toStringAsFixed(0)}'),
                Text('Phone: +250 ${_phoneController.text}'),
                const SizedBox(height: 16),
                const Text(
                  'Your payment is being processed and will be sent within 1 hour.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will receive an SMS confirmation once the payment is completed.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _phoneController.clear();
                  _amountController.clear();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green, size: 32),
              const SizedBox(width: 10),
              const Text(
                'Cashout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Withdraw your earnings to mobile money',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: A fee of 500 RWF will be deducted from your withdrawal amount.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // Current Balance Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'RWF 0',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Cashout Form
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Withdrawal Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phone Number
                  const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixText: '+250 ',
                      hintText: '7XXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  const Text('Amount (RWF)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Enter amount to withdraw',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  // Cashout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _processCashout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Cashout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildMyTasksTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your tasks.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('creator_id', isEqualTo: user.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tasks = snapshot.data?.docs ?? [];
        if (tasks.isEmpty) {
          return const Center(child: Text('You have not created any tasks yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            final title = (task['title'] ?? '').toString();
            final description = (task['description'] ?? '').toString();
            final reward = task['reward_per_task']?.toString() ?? '';
            final totalSlots = task['total_slots'] ?? 1;
            final slotsFilled = task['slots_filled'] ?? 0;
            final isActive = task['is_active'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Reward: RWF $reward | Completed: $slotsFilled / $totalSlots'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          isActive ? 'Approved' : 'Pending',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.green),
                      onPressed: () async {
                        // For demonstration, just set a placeholder image
                        setState(() {
                          _profileImageUrl = 'https://i.pravatar.cc/150?img=3';
                        });
                        // In production, implement image picker and upload to Firebase Storage
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: currentPassController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not logged in!')),
                  );
                  return;
                }
                if (newPassController.text != confirmPassController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match!')),
                  );
                  return;
                }
                // Re-authenticate user
                try {
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassController.text,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated!')),
                  );
                  currentPassController.clear();
                  newPassController.clear();
                  confirmPassController.clear();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}', style: TextStyle(color: Colors.white)));
          }
          final jobs = snapshot.data?.docs ?? [];
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs available.', style: TextStyle(color: Colors.white70)));
          }
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final jobDoc = jobs[index];
              final job = jobDoc.data() as Map<String, dynamic>;
              job['id'] = jobDoc.id;
              final title = (job['title'] ?? '').toString();
              final description = (job['description'] ?? '').toString();
              final reward = job['reward_per_task']?.toString() ?? '';
              final postedAt = (job['postedAt'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: const Color(0xFF23263A),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(job: job),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reward: RWF $reward',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.greenAccent,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted: $postedAt',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Icon(Icons.hub, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            const Text(
              'TaskHub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1ED760),
        elevation: 4,
        actions: [
          // Balance Display
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Card(
              color: Colors.white.withOpacity(0.15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'RWF 0',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notification Icon
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to view notifications'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Notifications'),
                          content: SizedBox(
                            width: 350,
                            height: 400,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                .collection('notifications')
                                .where('user_email', isEqualTo: user.email)
                                .orderBy('created_at', descending: true)
                                .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                final notifications = snapshot.data?.docs ?? [];
                                if (notifications.isEmpty) {
                                  return const Center(child: Text('No notifications.'));
                                }
                                return ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notifDoc = notifications[index];
                                    final notif = notifDoc.data() as Map<String, dynamic>;
                                    final message = notif['message'] ?? '';
                                    final createdAt = notif['created_at']?.toDate().toString().substring(0, 16) ?? '';
                                    final isRead = notif['read'] == true;
                                    return ListTile(
                                      leading: Icon(
                                        Icons.notifications,
                                        color: isRead ? Colors.grey : Colors.greenAccent,
                                      ),
                                      title: Text(
                                        message,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          color: isRead ? Colors.grey : Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(createdAt),
                                      tileColor: isRead ? Colors.grey[900] : Colors.greenAccent.withOpacity(0.1),
                                      onTap: () async {
                                        if (!isRead) {
                                          await notifDoc.reference.update({'read': true});
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
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
                  },
                ),
                // Notification Badge
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1ED760)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _onDrawerTap(0),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.green),
              title: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Cashout'),
              onTap: () => _onDrawerTap(1),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('My Tasks'),
              onTap: () => _onDrawerTap(2),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => _onDrawerTap(3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Unlock premium rewards'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upgrade to Premium'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To unlock premium features, please pay:'),
                        const SizedBox(height: 8),
                        const Text(
                          '3000 RWF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                        ),
                        const SizedBox(height: 16),
                        const Text('Send to:'),
                        Row(
                          children: [
                            const SelectableText('0790184899', style: TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Copy number',
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: '0790184899'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number copied!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const Text('Name: NIYOGISUBIZO Wilson'),
                        const SizedBox(height: 16),
                        const Text('After payment, your premium features will be unlocked.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Cashout'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'My Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
} 