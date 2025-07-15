import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorRequest {
  final String name;
  final String bloodType;
  final String location;
  final String available;
  String status; // 'pending', 'approved', 'rejected'
  DonorRequest({required this.name, required this.bloodType, required this.location, required this.available, this.status = 'pending'});
}

class DonorMapScreen extends StatelessWidget {
  final List<DonorRequest> donors;
  const DonorMapScreen({Key? key, required this.donors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder map UI
    return Scaffold(
      appBar: AppBar(title: Text('Donors on Map')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text('Map integration coming soon!'),
            SizedBox(height: 24),
            Text('Sample Donors:'),
            ...donors.map((d) => Text('${d.name} (${d.bloodType}) - ${d.location}')),
          ],
        ),
      ),
    );
  }
}

Future<void> showDonorSearchDialog(BuildContext context, List<DonorRequest> donors) async {
  String? selectedBlood;
  String? selectedLocation;
  List<String> bloodGroups = donors.map((d) => d.bloodType).toSet().toList();
  List<String> locations = donors.map((d) => d.location).toSet().toList();
  List<DonorRequest> filtered = donors;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Search Donors'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Blood Group'),
                  value: selectedBlood ?? 'Any',
                  items: ['Any', ...bloodGroups].map((b) => DropdownMenuItem<String>(value: b, child: Text(b))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedBlood = val == 'Any' ? null : val;
                      filtered = donors.where((d) => (selectedBlood == null || d.bloodType == selectedBlood) && (selectedLocation == null || d.location == selectedLocation)).toList();
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Location'),
                  value: selectedLocation ?? 'Any',
                  items: ['Any', ...locations].map((l) => DropdownMenuItem<String>(value: l, child: Text(l))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedLocation = val == 'Any' ? null : val;
                      filtered = donors.where((d) => (selectedBlood == null || d.bloodType == selectedBlood) && (selectedLocation == null || d.location == selectedLocation)).toList();
                    });
                  },
                ),
                SizedBox(height: 16),
                Text('Results:'),
                SizedBox(
                  height: 100,
                  width: 200,
                  child: ListView(
                    children: filtered.map((d) => ListTile(
                      title: Text('${d.name} (${d.bloodType})'),
                      subtitle: Text(d.location),
                    )).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}

class CollectorDashboard extends StatefulWidget {
  @override
  _CollectorDashboardState createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  // Add local state for requests
  List<DonorRequest> _requests = [
    DonorRequest(name: 'Alice Johnson', bloodType: 'A+', location: 'Kigali', available: '14 June, 10:00 AM'),
    DonorRequest(name: 'Bob Smith', bloodType: 'O-', location: 'Gisenyi', available: '15 June, 2:00 PM'),
  ];
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final isPrem = await _authService.isPremium(user.uid);
      setState(() {
        _isPremium = isPrem;
      });
    }
  }

  void _approveRequest(int index) {
    setState(() {
      _requests[index].status = 'approved';
    });
  }

  void _rejectRequest(int index) {
    setState(() {
      _requests[index].status = 'rejected';
    });
  }

  void _simulateCollectionPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Collected!'),
        content: Text('Collection payment was successful (simulated).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Go Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Subscribe for only 10 USD to unlock premium features!'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.payment),
              label: Text('Pay with PayPal'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                const url = 'https://www.paypal.me/yourusername/10'; // <-- REAL PAYPAL LINK
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Confirm payment
      final really = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Payment'),
          content: Text('Did you complete the PayPal payment?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes')),
          ],
        ),
      );
      if (really == true) {
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          await _authService.setPremium(user.uid, true);
          setState(() {
            _isPremium = true;
          });
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Premium Activated!'),
            content: Text('Thank you for subscribing. Premium features are now unlocked.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🩸 Collector Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab 1: Find Donors & Incoming Requests
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.amber[50],
                    child: ListTile(
                      leading: Icon(Icons.star, color: Colors.amber),
                      title: Text(_isPremium ? 'Premium Subscribed' : 'Go Premium'),
                      subtitle: Text(_isPremium ? 'You have access to premium features!' : 'Unlock advanced features and support our mission!'),
                      trailing: ElevatedButton(
                        onPressed: _isPremium ? null : _showPremiumDialog,
                        child: Text(_isPremium ? 'Subscribed' : 'Go Premium'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      ),
                    ),
                  ),
                  Text(
                    'Incoming Requests from Donors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ..._requests.map((req) {
                    int idx = _requests.indexOf(req);
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.person, color: Colors.red),
                        title: Text('${req.name} (${req.bloodType})'),
                        subtitle: Text('Location: ${req.location}\nAvailable: ${req.available}'),
                        trailing: req.status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _approveRequest(idx),
                                    tooltip: 'Approve',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _rejectRequest(idx),
                                    tooltip: 'Reject',
                                  ),
                                ],
                              )
                            : req.status == 'approved'
                                ? Chip(label: Text('Approved'), backgroundColor: Colors.green[100])
                                : Chip(label: Text('Rejected'), backgroundColor: Colors.red[100]),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  Text(
                    'Find Donors (Search Tool)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.search, color: Colors.red),
                      title: Text('Search Donors'),
                      subtitle: Text('Filter by blood group, location, eligibility, urgency'),
                      trailing: Icon(Icons.tune),
                      onTap: () => showDonorSearchDialog(context, _requests),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Map Integration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.map, color: Colors.red),
                      title: Text('View Donors on Map'),
                      subtitle: Text('Visualize and plan routes for collections'),
                      trailing: Icon(Icons.navigation),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorMapScreen(donors: _requests),
                        ),
                      ),
                    ),
                  ),
                  if (_isPremium)
                    Card(
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: Icon(Icons.analytics, color: Colors.blue),
                        title: Text('Advanced Analytics'),
                        subtitle: Text('See collection trends and stats.'),
                      ),
                    ),
                    Card(
                      color: Colors.green[50],
                      child: ListTile(
                        leading: Icon(Icons.file_download, color: Colors.green),
                        title: Text('Export Data'),
                        subtitle: Text('Export collection history as PDF or Excel.'),
                      ),
                    ),
                    Card(
                      color: Colors.purple[50],
                      child: ListTile(
                        leading: Icon(Icons.support_agent, color: Colors.purple),
                        title: Text('Priority Support'),
                        subtitle: Text('Get help faster with premium support.'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Tab 2: Requests, Inventory, History, Export
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Text(
                    'Schedule Collection Appointments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.event, color: Colors.red),
                      title: Text('Schedule with Alice Johnson'),
                      subtitle: Text('14 June, 10:00 AM'),
                      trailing: Icon(Icons.edit),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Request Blood (if needed)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.bloodtype, color: Colors.red),
                      title: Text('Need A+ in Kigali'),
                      subtitle: Text('Urgency: Critical'),
                      trailing: Icon(Icons.warning, color: Colors.red),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Blood Inventory Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.inventory, color: Colors.red),
                      title: Text('O+: 5 units, A-: 2 units'),
                      subtitle: Text('Warning: B- is low!'),
                      trailing: Icon(Icons.error, color: Colors.orange),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Collection History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.history, color: Colors.red),
                      title: Text('Alice Johnson'),
                      subtitle: Text('14 June, 10:00 AM • Successful • Kigali'),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.history, color: Colors.red),
                      title: Text('Bob Smith'),
                      subtitle: Text('15 June, 2:00 PM • Missed • Gisenyi'),
                      trailing: Icon(Icons.cancel, color: Colors.red),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Export/Report Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text('Export Collection Report'),
                      subtitle: Text('Generate PDF or Excel for records'),
                      trailing: Icon(Icons.download),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab 3: Profile & Notifications
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Text(
                    'Collector Profile & Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.red),
                      title: Text('Jane Collector'),
                      subtitle: Text('Role: Blood Collector\nDonors served: 42\nUnits collected: 120'),
                      trailing: Icon(Icons.edit),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Notifications/Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: Colors.red),
                      title: Text('New donation offer from Alice Johnson'),
                      subtitle: Text('Check incoming requests tab.'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.warning, color: Colors.orange),
                      title: Text('Low inventory alert'),
                      subtitle: Text('B- blood type is running low.'),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Settings & Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.settings, color: Colors.red),
                      title: Text('App Settings'),
                      subtitle: Text('Notifications, privacy, and app preferences'),
                      trailing: Icon(Icons.arrow_forward),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.help, color: Colors.red),
                      title: Text('Help & Support'),
                      subtitle: Text('FAQ, contact support, and user guide'),
                      trailing: Icon(Icons.arrow_forward),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Donors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Collections',
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
