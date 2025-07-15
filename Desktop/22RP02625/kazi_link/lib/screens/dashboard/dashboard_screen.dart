import 'package:flutter/material.dart';
import '../jobs/job_list_screen.dart';
import '../messaging/messaging_screen.dart';
import '../profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/admob_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _role = 'worker'; // Change to 'client' to test client view

  final List<String> _tabs = ['Home', 'Jobs', 'Messages', 'Profile'];

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Already on Dashboard (Home)
        break;
      case 1:
        _navigateWithTransition(context, const JobListScreen());
        break;
      case 2:
        _navigateWithTransition(context, const MessagingScreen());
        break;
      case 3:
        _navigateWithTransition(context, const ProfileScreen());
        break;
    }
  }

  void _onCardTap(String type) {
    if (type == 'jobs') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Jobs Applied'),
          content: const Text('You have applied to 12 jobs. (Demo)'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } else if (type == 'rating') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Rating'),
          content: const Text('Your average rating is 4.8. (Demo)'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? navRole = ModalRoute.of(context)?.settings.arguments as String?;
    final String? providerRole = Provider.of<UserProvider>(context).role;
    final String role = navRole ?? providerRole ?? _role;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.handshake, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Text('KaziLink', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.onPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == 'worker' ? 'Welcome, Worker!' : 'Welcome, Client!',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onBackground),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onCardTap('jobs'),
                        child: _DashboardCard(
                          icon: Icons.work,
                          label: role == 'worker' ? 'Jobs Applied' : 'Jobs Posted',
                          value: '12',
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onCardTap('rating'),
                        child: _DashboardCard(
                          icon: Icons.star,
                          label: 'Rating',
                          value: '4.8',
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  role == 'worker' ? 'Quick Actions' : 'Your Activity',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onBackground),
                ),
                const SizedBox(height: 12),
                if (role == 'worker') ...[
                  _DashboardActionTile(
                    icon: Icons.search,
                    label: 'Browse Jobs',
                    onTap: () => Navigator.pushNamed(context, '/jobs'),
                  ),
                  const SizedBox(height: 8),
                  _DashboardActionTile(
                    icon: Icons.star,
                    label: 'View Reviews',
                    onTap: () => Navigator.pushNamed(context, '/reviews'),
                  ),
                ] else ...[
                  _ClientDashboard(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
              NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
            height: 68,
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Color(0xFF1976D2),
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return AdMobBanner(showAd: !userProvider.isPremium);
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DashboardCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 15, color: colorScheme.onBackground.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 28),
      title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: colorScheme.surface,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}

void _navigateWithTransition(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

class _ClientDashboard extends StatefulWidget {
  @override
  State<_ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<_ClientDashboard> {
  List<Map<String, dynamic>> jobs = [
    {
      'title': 'Fix kitchen sink',
      'status': 'Open',
      'applicants': [
        {'name': 'Alice Worker', 'rating': 4.9},
        {'name': 'Bob Worker', 'rating': 4.7},
      ],
    },
    {
      'title': 'Design logo',
      'status': 'In Progress',
      'applicants': [
        {'name': 'Carol Worker', 'rating': 4.8},
      ],
    },
  ];

  int _selectedTab = 0;
  final List<String> _tabs = [
    'My Jobs',
    'Messages',
    'Payments',
    'Reviews',
    'Notifications',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) => ChoiceChip(
              label: Text(_tabs[idx]),
              selected: _selectedTab == idx,
              onSelected: (_) => setState(() => _selectedTab = idx),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedTab == 0) ...[
          // My Jobs
          Text('My Jobs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ...jobs.map((job) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Text(job['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('Status: ${job['status']}', style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))),
                  children: [
                    ListTile(
                      title: Text('Applicants', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...job['applicants'].map<Widget>((a) => ListTile(
                                leading: Icon(Icons.person, size: 24),
                                title: Text(a['name'], style: GoogleFonts.poppins(fontSize: 14)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(a['rating'].toString(), style: GoogleFonts.poppins(fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.message),
                                      onPressed: () {
                                        // Open chat with applicant
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open chat (stub)')));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () {
                                        // Accept applicant
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted (stub)')));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () {
                                        // Reject applicant
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected (stub)')));
                                      },
                                    ),
                                  ],
                                ),
                              ))
                        ],
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Edit job
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit job (stub)')));
                          },
                          child: Text('Edit', style: GoogleFonts.poppins(fontSize: 14)),
                        ),
                        TextButton(
                          onPressed: () {
                            // Delete job
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete job (stub)')));
                          },
                          child: Text('Delete', style: GoogleFonts.poppins(fontSize: 14)),
                        ),
                        TextButton(
                          onPressed: () {
                            // Mark as completed
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as completed (stub)')));
                          },
                          child: Text('Mark Completed', style: GoogleFonts.poppins(fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.post_add, size: 24),
              label: Text('Post a New Job', style: GoogleFonts.poppins(fontSize: 16)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => _PostJobSheet(),
                );
              },
            ),
          ),
        ] else if (_selectedTab == 1) ...[
          // Messaging Center
          Text('Messaging Center', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.message, size: 28),
            title: Text('View all conversations', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () => Navigator.pushNamed(context, '/messaging'),
          ),
        ] else if (_selectedTab == 2) ...[
          // Payments & Invoices
          Text('Payments & Invoices', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.payment, size: 28),
            title: Text('View payment history', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () => Navigator.pushNamed(context, '/payment'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long, size: 28),
            title: Text('View invoices', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {},
          ),
        ] else if (_selectedTab == 3) ...[
          // Ratings & Reviews
          Text('Ratings & Reviews', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.star, size: 28),
            title: Text('Rate a worker', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.reviews, size: 28),
            title: Text('View your reviews', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () => Navigator.pushNamed(context, '/reviews'),
          ),
        ] else if (_selectedTab == 4) ...[
          // Notifications
          Text('Notifications', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.notifications, size: 28),
            title: Text('No new notifications (demo)', style: GoogleFonts.poppins(fontSize: 16)),
          ),
        ] else if (_selectedTab == 5) ...[
          // Profile & Settings
          Text('Profile & Settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.person, size: 28),
            title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: Icon(Icons.settings, size: 28),
            title: Text('Account Settings', style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _PostJobSheet extends StatefulWidget {
  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String category = '';
  String location = '';
  String budget = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Post a Job', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Job Title', labelStyle: GoogleFonts.poppins(fontSize: 14)),
                validator: (val) => val == null || val.isEmpty ? 'Enter job title' : null,
                onSaved: (val) => title = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description', labelStyle: GoogleFonts.poppins(fontSize: 14)),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Enter description' : null,
                onSaved: (val) => description = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Category', labelStyle: GoogleFonts.poppins(fontSize: 14)),
                validator: (val) => val == null || val.isEmpty ? 'Enter category' : null,
                onSaved: (val) => category = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Location', labelStyle: GoogleFonts.poppins(fontSize: 14)),
                validator: (val) => val == null || val.isEmpty ? 'Enter location' : null,
                onSaved: (val) => location = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Budget', labelStyle: GoogleFonts.poppins(fontSize: 14)),
                validator: (val) => val == null || val.isEmpty ? 'Enter budget' : null,
                onSaved: (val) => budget = val ?? '',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      // Here you would add the job to your backend or state
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Job posted! (Demo)'), backgroundColor: Theme.of(context).colorScheme.primary),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Post Job', style: GoogleFonts.poppins(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 