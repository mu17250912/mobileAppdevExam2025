import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({Key? key}) : super(key: key);
  @override
  _DonorDashboardState createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _hasResponded = false;
  DateTime _appointmentDateTime = DateTime(2024, 6, 12, 10, 0);
  bool _appointmentCanceled = false;
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
      if (!mounted) return;
      setState(() {
        _isPremium = isPrem;
      });
    }
  }

  void _simulatePayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thank You!'),
        content: Text('Your donation/payment was successful (simulated).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRespondedDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Responded successfully'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _hasResponded = true;
    });
  }

  void _handleLogout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rescheduleAppointment() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_appointmentDateTime),
      );
      if (pickedTime != null) {
        if (!mounted) return;
        setState(() {
          _appointmentDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rescheduled!'),
            content: const Text('Your appointment has been rescheduled.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        _appointmentCanceled = true;
      });
    }
  }

  void _showPremiumDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Subscribe for only 10 USD to unlock premium features!'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Pay with PayPal'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                const url = 'https://www.paypal.me/yourusername/10';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (Navigator.canPop(context)) Navigator.pop(context, true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final really = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: const Text('Did you complete the PayPal payment?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        ),
      );
      if (really == true) {
        final user = _firebaseAuth.currentUser;
        if (user != null) {
          await _authService.setPremium(user.uid, true);
          if (!mounted) return;
          setState(() {
            _isPremium = true;
          });
        }
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Premium Activated!'),
            content: const Text('Thank you for subscribing. Premium features are now unlocked.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩸 Donor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.amber[50],
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(_isPremium ? 'Premium Subscribed' : 'Go Premium'),
                  subtitle: Text(_isPremium ? 'You have access to premium features!' : 'Unlock advanced features and support our mission!'),
                  trailing: ElevatedButton(
                    onPressed: _isPremium ? null : _showPremiumDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    child: Text(_isPremium ? 'Subscribed' : 'Go Premium'),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to Blood Donor App!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text('Thank you for your commitment to saving lives'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('Donate (Simulated Payment)'),
                  onPressed: _simulatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: const Text('5 Donations'),
                    avatar: const Icon(Icons.emoji_events, color: Colors.amber),
                    backgroundColor: Colors.red[50],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('Request to Donate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request to donate sent! (placeholder)')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upcoming Donation Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Colors.red),
                  title: Text(_formatAppointmentDateTime(_appointmentDateTime)),
                  subtitle: const Text('Red Cross Center, Main St.'),
                  trailing: _appointmentCanceled
                      ? const Chip(label: Text('Canceled', style: TextStyle(color: Colors.white)), backgroundColor: Colors.grey)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(onPressed: _appointmentCanceled ? null : _cancelAppointment, child: const Text('Cancel', style: TextStyle(color: Colors.red))),
                            TextButton(onPressed: _appointmentCanceled ? null : _rescheduleAppointment, child: const Text('Reschedule', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Donation History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.red),
                  title: const Text('Wed, 10 May 2024, 9:00 AM'),
                  subtitle: const Text('Whole Blood • Red Cross Center'),
                  trailing: const Chip(label: Text('Completed'), backgroundColor: Color(0xFFA5D6A7)),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.red),
                  title: const Text('Tue, 2 Apr 2024, 2:00 PM'),
                  subtitle: const Text('Plasma • City Hospital'),
                  trailing: const Chip(label: Text('Missed'), backgroundColor: Color(0xFFFFE082)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Center',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.red),
                  title: const Text('Urgent: O+ needed at City Hospital'),
                  subtitle: const Text('2 units required'),
                  trailing: ElevatedButton(
                    onPressed: _hasResponded ? null : _showRespondedDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text(_hasResponded ? 'Responded' : 'Respond'),
                  ),
                ),
              ),
              if (_isPremium)
                Column(
                  children: [
                    Card(
                      color: Colors.blue[50],
                      child: const ListTile(
                        leading: Icon(Icons.analytics, color: Colors.blue),
                        title: Text('Advanced Analytics'),
                        subtitle: Text('See your donation trends and stats.'),
                      ),
                    ),
                    Card(
                      color: Colors.green[50],
                      child: const ListTile(
                        leading: Icon(Icons.file_download, color: Colors.green),
                        title: Text('Export Data'),
                        subtitle: Text('Export your donation history as PDF or Excel.'),
                      ),
                    ),
                    Card(
                      color: Colors.purple[50],
                      child: const ListTile(
                        leading: Icon(Icons.support_agent, color: Colors.purple),
                        title: Text('Priority Support'),
                        subtitle: Text('Get help faster with premium support.'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatAppointmentDateTime(DateTime dt) {
  return '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} ${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
}

String _weekday(int w) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[w - 1];
}

String _month(int m) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[m - 1];
}
