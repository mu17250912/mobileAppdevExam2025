import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterEmail = '';
  String _filterMethod = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 4 -> 6 tabs
  }

  void _showAddDialog() {
    switch (_tabController.index) {
      case 0:
        _showAddAlertDialog();
        break;
      case 1:
        _showAddUserDialog();
        break;
      case 2:
        _showAddAnnouncementDialog();
        break;
      case 3:
        _showAddAnalyticsDialog();
        break;
      case 4:
        _showAddEmergencyContactDialog();
        break;
      case 5:
        // Payments are not added manually
        break;
    }
  }

  void _showAddAlertDialog() {
    final _formKey = GlobalKey<FormState>();
    String type = '';
    String description = '';
    String location = '';
    String userId = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Alert'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Type'),
                  onChanged: (v) => type = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (v) => description = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (v) => location = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'User ID'),
                  onChanged: (v) => userId = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('alerts').add({
                  'type': type,
                  'description': description,
                  'location': location,
                  'dateTime': DateTime.now(),
                  'userId': userId,
                  'status': 'pending',
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordHashController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: passwordHashController,
                  decoration: const InputDecoration(labelText: 'Password Hash'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('users').add({
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'passwordHash': passwordHashController.text,
                });
                nameController.clear();
                emailController.clear();
                phoneController.clear();
                passwordHashController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User added successfully!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String message = '';
    String author = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Announcement'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (v) => title = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Message'),
                  onChanged: (v) => message = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Author'),
                  onChanged: (v) => author = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('announcements').add({
                  'title': title,
                  'message': message,
                  'author': author,
                  'dateTime': DateTime.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAnalyticsDialog() {
    final _formKey = GlobalKey<FormState>();
    String totalAlerts = '';
    String totalUsers = '';
    String resolvedAlerts = '';
    String activeUsers = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Analytics'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Total Alerts'),
                  onChanged: (v) => totalAlerts = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Total Users'),
                  onChanged: (v) => totalUsers = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Resolved Alerts'),
                  onChanged: (v) => resolvedAlerts = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Active Users'),
                  onChanged: (v) => activeUsers = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('analytics').add({
                  'totalAlerts': int.tryParse(totalAlerts) ?? 0,
                  'totalUsers': int.tryParse(totalUsers) ?? 0,
                  'resolvedAlerts': int.tryParse(resolvedAlerts) ?? 0,
                  'activeUsers': int.tryParse(activeUsers) ?? 0,
                  'dateTime': DateTime.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddEmergencyContactDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String type = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) => name = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onChanged: (v) => phone = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Type (e.g. Police, Fire)'),
                  onChanged: (v) => type = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('emergency_contacts').add({
                  'name': name,
                  'phone': phone,
                  'type': type,
                });
                if (mounted) {
                  setState(() {}); // Refresh UI
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency contact added successfully!')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEmergencyContactDialog(DocumentSnapshot contact) {
    final _formKey = GlobalKey<FormState>();
    final data = contact.data() as Map<String, dynamic>;
    String name = data['name'] ?? '';
    String phone = data['phone'] ?? '';
    String type = data['type'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) => name = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onChanged: (v) => phone = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type (e.g. Police, Fire)'),
                  onChanged: (v) => type = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await contact.reference.update({
                  'name': name,
                  'phone': phone,
                  'type': type,
                });
                if (mounted) {
                  setState(() {}); // Refresh UI
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency contact updated successfully!')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Add this method to show the send broadcast alert dialog
  void _showSendBroadcastAlertDialog() {
    final _formKey = GlobalKey<FormState>();
    String type = '';
    String description = '';
    String location = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Broadcast Alert'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Type (e.g. Fire, Medical, Accident)'),
                  onChanged: (v) => type = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (v) => description = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (v) => location = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('alerts').add({
                  'type': type,
                  'description': description,
                  'location': location,
                  'dateTime': DateTime.now(),
                  'status': 'broadcast',
                  'isBroadcast': true,
                });
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broadcast alert sent to all users!')),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(DocumentSnapshot announcement) {
    final _formKey = GlobalKey<FormState>();
    final data = announcement.data() as Map<String, dynamic>;
    String title = data['title'] ?? '';
    String message = data['message'] ?? '';
    String author = data['author'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (v) => title = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: message,
                  decoration: const InputDecoration(labelText: 'Message'),
                  onChanged: (v) => message = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: author,
                  decoration: const InputDecoration(labelText: 'Author'),
                  onChanged: (v) => author = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await announcement.reference.update({
                  'title': title,
                  'message': message,
                  'author': author,
                });
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement updated successfully!')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePricingDialog() {
    final _formKey = GlobalKey<FormState>();
    String plan = '';
    String price = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Pricing/Plan'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Plan Name'),
                onChanged: (v) => plan = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price (USD)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => price = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('pricing').doc(plan).set({
                  'plan': plan,
                  'price': double.tryParse(price) ?? 0,
                  'updatedAt': DateTime.now(),
                });
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pricing/plan updated!')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Alerts', icon: Icon(Icons.warning)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Announcements', icon: Icon(Icons.campaign)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Emergency Info', icon: Icon(Icons.phone_in_talk)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Alerts Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    label: const Text('Send Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showSendBroadcastAlertDialog,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('alerts').orderBy('dateTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No alerts found.'));
              }
              final alerts = snapshot.data!.docs;
              return ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final data = alert.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  final type = data['type'] ?? 'Alert';
                  final date = data['dateTime'] != null
                      ? (data['dateTime'] as Timestamp).toDate()
                      : DateTime.now();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(type),
                                backgroundColor: Colors.red[100],
                                avatar: const Icon(Icons.warning, color: Colors.red),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor: status == 'approved'
                                    ? Colors.green[100]
                                    : status == 'resolved'
                                        ? Colors.blue[100]
                                        : Colors.orange[100],
                                labelStyle: TextStyle(
                                  color: status == 'approved'
                                      ? Colors.green
                                      : status == 'resolved'
                                          ? Colors.blue
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(data['location'] ?? '', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                    if (status == 'pending') ...[
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Approve',
                                onPressed: () async {
                                  await alert.reference.update({'status': 'approved'});
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Alert approved!')),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        tooltip: 'Reject',
                                        onPressed: () async {
                                          await alert.reference.update({'status': 'rejected'});
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Alert rejected.')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                    if (status == 'approved') ...[
                              IconButton(
                                icon: const Icon(Icons.done_all, color: Colors.blue),
                                tooltip: 'Resolve',
                                onPressed: () async {
                                  await alert.reference.update({'status': 'resolved'});
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Alert marked as resolved.')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  await alert.reference.delete();
                                        if (mounted) {
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Alert deleted.')),
                                          );
                                        }
                                },
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
                ),
              ),
            ],
          ),
          // Users Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-user-management');
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Manage User Roles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }
              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(data['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['email'] ?? ''),
                          Text(data['phone'] ?? ''),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Status: ${data['status'] ?? 'pending'}'),
                                      backgroundColor: (data['status'] ?? 'pending') == 'active' 
                                        ? Colors.green 
                                        : Colors.orange,
                                      labelStyle: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Role: ${data['role'] ?? 'user'}'),
                                      backgroundColor: (data['role'] ?? 'user') == 'admin' 
                                        ? Colors.red 
                                        : Colors.grey,
                                      labelStyle: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((data['status'] ?? 'pending') == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: () async {
                                      await user.reference.update({'status': 'active'});
                                      if (mounted) {
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User approved!')),
                                        );
                                      }
                                    },
                                  ),
                                if ((data['status'] ?? 'active') == 'active')
                                  IconButton(
                                    icon: const Icon(Icons.block, color: Colors.red),
                                    tooltip: 'Deactivate',
                                    onPressed: () async {
                                      await user.reference.update({'status': 'inactive'});
                                      if (mounted) {
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User deactivated.')),
                                        );
                                      }
                                    },
                                  ),
                                if ((data['status'] ?? '') == 'inactive')
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.blue),
                                    tooltip: 'Reactivate',
                                    onPressed: () async {
                                      await user.reference.update({'status': 'active'});
                                      if (mounted) {
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User reactivated!')),
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
              ),
            ],
          ),
          // Announcements Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').orderBy('dateTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No announcements found.'));
              }
              final announcements = snapshot.data!.docs;
              return ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  final data = ann.data() as Map<String, dynamic>;
                  final date = data['dateTime'] != null
                      ? (data['dateTime'] as Timestamp).toDate()
                      : DateTime.now();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.campaign, color: Colors.deepOrange),
                      title: Text(data['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['message'] ?? ''),
                          Text(
                            "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text('By: ${data['author'] ?? 'Admin'}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditAnnouncementDialog(ann);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () async {
                              await ann.reference.delete();
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Announcement deleted successfully!')),
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
          // Analytics Tab
          AnalyticsTab(),
          // Emergency Info Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('emergency_contacts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No emergency contacts found.'));
              }
              final contacts = snapshot.data!.docs;
              return ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final data = contact.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.redAccent),
                      title: Text(data['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['phone'] ?? ''),
                          Text(data['type'] ?? ''),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditEmergencyContactDialog(contact);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () async {
                              await contact.reference.delete();
                              if (mounted) {
                                setState(() {}); // Refresh UI
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Emergency contact deleted successfully!')),
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
          // Payments Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Filter by Email'),
                        onChanged: (v) => setState(() => _filterEmail = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Filter by Method'),
                        onChanged: (v) => setState(() => _filterMethod = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                      child: const Text('Date Range'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.price_change),
                      label: const Text('Update Pricing'),
                      onPressed: _showUpdatePricingDialog,
                    ),
                  ],
                ),
              ),
              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('payments').get(),
                  builder: (context, snapshot) {
                    double totalRevenue = 0;
                    double totalCommission = 0;
                    double providerEarnings = 0;
                    if (snapshot.hasData) {
                      final docs = snapshot.data!.docs;
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final amount = (data['amount'] ?? 0).toDouble();
                        final commission = (data['commission'] ?? 0).toDouble();
                        final provider = (data['providerAmount'] ?? 0).toDouble();
                        totalRevenue += amount;
                        totalCommission += commission;
                        providerEarnings += provider;
                      }
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _summaryCard('Total Revenue', totalRevenue, Colors.blue),
                        _summaryCard('Commission', totalCommission, Colors.orange),
                        _summaryCard('Provider', providerEarnings, Colors.green),
                      ],
                    );
                  },
                ),
              ),
              // Payment list with filters
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('payments').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No payments found.'));
                    }
                    var payments = snapshot.data!.docs;
                    payments = payments.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final emailMatch = _filterEmail.isEmpty || (data['email'] ?? '').toString().toLowerCase().contains(_filterEmail.toLowerCase());
                      final methodMatch = _filterMethod.isEmpty || (data['method'] ?? '').toString().toLowerCase().contains(_filterMethod.toLowerCase());
                      final date = data['timestamp'] is DateTime ? data['timestamp'] : (data['timestamp'] as Timestamp?)?.toDate();
                      final dateMatch = (_startDate == null || _endDate == null) || (date != null && date.isAfter(_startDate!) && date.isBefore(_endDate!));
                      return emailMatch && methodMatch && dateMatch;
                    }).toList();
                    return ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        final data = payment.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.payment, color: Colors.green),
                            title: Text('User: ${data['email'] ?? data['userId'] ?? ''}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User ID: ${data['userId'] ?? ''}'),
                                Text('Email: ${data['email'] ?? ''}'),
                                Text('Amount:  \$${data['amount']?.toStringAsFixed(2) ?? data['amount'] ?? ''}'),
                                Text('Method: ${data['method'] ?? ''}'),
                                Text('Commission:  \$${data['commission']?.toStringAsFixed(2) ?? data['commission'] ?? ''}'),
                                Text('Provider Receives:  \$${data['providerAmount']?.toStringAsFixed(2) ?? data['providerAmount'] ?? ''}'),
                                Text('Type: ${data['type'] ?? ''}'),
                                Text('Time: ${data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : ''}'),
                                // Show any other fields dynamically
                                ...data.entries.where((e) => !['userId','email','amount','method','commission','providerAmount','timestamp','type'].contains(e.key)).map((e) => Text('${e.key}: ${e.value}')),
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
          ),
        ],
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('alerts').get(),
        FirebaseFirestore.instance.collection('users').get(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data![0].docs;
        final users = snapshot.data![1].docs;
        final resolvedAlerts = alerts.where((a) => (a.data() as Map<String, dynamic>)['status'] == 'resolved').length;
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Total Alerts: ${alerts.length}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              Text('Total Users: ${users.length}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              Text('Resolved Alerts: $resolvedAlerts', style: const TextStyle(fontSize: 20)),
            ],
          ),
        );
      },
    );
  }
}

Widget _summaryCard(String title, double value, Color color) {
  return Card(
    color: color.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(' 24${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: color)),
        ],
      ),
    ),
  );
} 