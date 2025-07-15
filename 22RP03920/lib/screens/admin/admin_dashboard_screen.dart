import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCare Admin'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {}, // To be implemented
            tooltip: 'Notifications',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Settings'),
                          content: Row(
                            children: [
                              const Icon(Icons.brightness_6),
                              const SizedBox(width: 12),
                              const Text('Dark Mode'),
                              const Spacer(),
                              Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (val) {
                                  themeProvider.toggleTheme();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  break;
                case 'logout':
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/signin');
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.medical_services), text: 'Doctors'),
            Tab(icon: Icon(Icons.book_online), text: 'Appointments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildUsersTab(),
          _buildDoctorsTab(),
          _buildAppointmentsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    // Show admin info at the top
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.usersCollection.doc(_authService.getCurrentUser()?.uid ?? '').get(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final adminData = adminSnapshot.data?.data() as Map<String, dynamic>?;
        final adminName = adminData?['name'] ?? 'Admin';
        final adminEmail = adminData?['email'] ?? '';
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $adminName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(adminEmail, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text('Role: Admin', style: TextStyle(fontSize: 15, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<int>>(
                future: Future.wait([
                  _firestoreService.usersCollection.get().then((s) => s.docs.length),
                  _firestoreService.usersCollection.where('role', isEqualTo: 'doctor').get().then((s) => s.docs.length),
                  _firestoreService.appointmentsCollection.get().then((s) => s.docs.length),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Total Users: ${data[0]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Total Doctors: ${data[1]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Total Appointments: ${data[2]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildUsersTab() {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.usersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs;
        return ListView.builder(
              padding: const EdgeInsets.all(16),
          itemCount: users.length,
              itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(user['name'] ?? 'No name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (user['isPremium'] == true) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    const Text('Premium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(user['email'] ?? 'No email', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(user['role'] ?? 'No role', style: const TextStyle(fontSize: 15, color: Colors.blue)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          tooltip: 'Edit',
                          onPressed: () async {
                            final nameController = TextEditingController(text: user['name'] ?? '');
                            final emailController = TextEditingController(text: user['email'] ?? '');
                            String selectedRole = user['role'] ?? 'patient';
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit User'),
                                content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(labelText: 'Name'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: emailController,
                                      decoration: const InputDecoration(labelText: 'Email'),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: selectedRole,
                                      items: const [
                                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                        DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                                        DropdownMenuItem(value: 'patient', child: Text('Patient')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) selectedRole = value;
                                      },
                                      decoration: const InputDecoration(labelText: 'Role'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Name and Email cannot be empty.')),
                                        );
                                        return;
                                      }
                                      try {
                                        await _firestoreService.usersCollection.doc(userId).update({
                                          'name': nameController.text.trim(),
                                          'email': emailController.text.trim(),
                                          'role': selectedRole,
                                        });
                                        Navigator.pop(context, true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('User updated successfully.')),
                                        );
                                      } catch (e) {
                                        Navigator.pop(context, false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error updating user: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User'),
                                content: const Text('Are you sure you want to delete this user?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await _firestoreService.usersCollection.doc(userId).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('User deleted successfully.')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error deleting user: $e')),
                                );
                              }
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
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () async {
              final nameController = TextEditingController();
              final emailController = TextEditingController();
              String selectedRole = 'patient';
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add User'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                          DropdownMenuItem(value: 'patient', child: Text('Patient')),
                        ],
                        onChanged: (value) {
                          if (value != null) selectedRole = value;
                        },
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name and Email cannot be empty.')),
                          );
                          return;
                        }
                        try {
                          await _firestoreService.usersCollection.add({
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'role': selectedRole,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          Navigator.pop(context, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User added successfully.')),
                          );
                        } catch (e) {
                          Navigator.pop(context, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding user: $e')),
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.doctorsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong fetching doctors.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final doctors = snapshot.data!.docs;
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors available.'));
          }
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index].data() as Map<String, dynamic>;
              final doctorId = doctors[index].id;
              return ListTile(
                title: Text(doctor['name'] ?? 'No name'),
                subtitle: Text(doctor['specialty'] ?? 'No specialty'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: 'Edit',
                      onPressed: () => _showEditDoctorDialog(doctor, doctorId),
                    ),
                    IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                          await _firestoreService.doctorsCollection.doc(doctorId).delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Doctor deleted successfully.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting doctor: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDoctorDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDoctorDialog() {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final locationController = TextEditingController();
    final experienceController = TextEditingController();
    final educationController = TextEditingController();
    final feeController = TextEditingController();
    final aboutController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
            return AlertDialog(
          title: const Text('Add Doctor'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  TextFormField(
                        controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                  TextFormField(
                        controller: specialtyController,
                        decoration: const InputDecoration(labelText: 'Specialty'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration: const InputDecoration(labelText: 'Experience'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: educationController,
                    decoration: const InputDecoration(labelText: 'Education'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: feeController,
                    decoration: const InputDecoration(labelText: 'Consultation Fee (RWF)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: aboutController,
                    decoration: const InputDecoration(labelText: 'About'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
              ),
              actions: [
                TextButton(
              onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final doctorData = {
                    'name': nameController.text.trim(),
                    'specialty': specialtyController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'email': emailController.text.trim(),
                    'location': locationController.text.trim(),
                    'experience': experienceController.text.trim(),
                    'education': educationController.text.trim(),
                    'fee': feeController.text.trim(),
                    'about': aboutController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  try {
                    await _firestoreService.doctorsCollection.add(doctorData);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor added successfully.')),
                    );
                  } catch (e) {
                Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding doctor: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDoctorDialog(Map<String, dynamic> doctor, String doctorId) {
    final nameController = TextEditingController(text: doctor['name'] ?? '');
    final specialtyController = TextEditingController(text: doctor['specialty'] ?? '');
    final phoneController = TextEditingController(text: doctor['phone'] ?? '');
    final emailController = TextEditingController(text: doctor['email'] ?? '');
    final locationController = TextEditingController(text: doctor['location'] ?? '');
    final experienceController = TextEditingController(text: doctor['experience'] ?? '');
    final educationController = TextEditingController(text: doctor['education'] ?? '');
    final feeController = TextEditingController(text: doctor['fee'] ?? doctor['consultationFee'] ?? '');
    final aboutController = TextEditingController(text: doctor['about'] ?? '');
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Doctor'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: specialtyController,
                    decoration: const InputDecoration(labelText: 'Specialty'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration: const InputDecoration(labelText: 'Experience'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: educationController,
                    decoration: const InputDecoration(labelText: 'Education'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: feeController,
                    decoration: const InputDecoration(labelText: 'Consultation Fee (RWF)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: aboutController,
                    decoration: const InputDecoration(labelText: 'About'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  try {
                    await _firestoreService.doctorsCollection.doc(doctorId).update({
                      'name': nameController.text.trim(),
                      'specialty': specialtyController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'location': locationController.text.trim(),
                      'experience': experienceController.text.trim(),
                      'education': educationController.text.trim(),
                      'fee': feeController.text.trim(),
                      'about': aboutController.text.trim(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor updated successfully.')),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating doctor: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.appointmentsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong fetching appointments.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = snapshot.data!.docs;
        if (appointments.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index].data() as Map<String, dynamic>;
            final appointmentId = appointments[index].id;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.event, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          appointment['status']?.toUpperCase() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          '${appointment['date'] ?? ''} at ${appointment['timeSlot'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Patient: ${appointment['patientName'] ?? ''}', style: const TextStyle(fontSize: 15)),
                    Text('Doctor: ${appointment['doctorName'] ?? ''}', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (appointment['status'] == 'pending')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Approve Appointment'),
                                  content: const Text('Are you sure you want to approve this appointment?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _firestoreService.updateAppointmentStatus(appointmentId, 'approved');
                                // Save notification to Firestore for the patient
                                final patientId = appointment['patientId'] ?? appointment['userId'];
                                final doctorName = appointment['doctorName'] ?? '';
                                final date = appointment['date'] ?? '';
                                final time = appointment['timeSlot'] ?? '';
                                await NotificationService().saveNotificationToFirestore(
                                  userId: patientId,
                                  title: 'Appointment Approved',
                                  message: 'Your appointment with Dr. $doctorName on $date at $time has been approved!',
                                  appointmentId: appointmentId,
                                  status: 'approved',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Appointment approved and patient notified.')),
                                  );
                                }
                              }
                            },
                            child: const Text('Approve', style: TextStyle(color: Colors.white)),
                          ),
                        if (appointment['status'] == 'pending')
                          const SizedBox(width: 12),
                        if (appointment['status'] == 'pending')
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Reject Appointment'),
                                  content: const Text('Are you sure you want to reject this appointment?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _firestoreService.updateAppointmentStatus(appointmentId, 'rejected');
                                // Save notification to Firestore for the patient
                                final patientId = appointment['patientId'] ?? appointment['userId'];
                                final doctorName = appointment['doctorName'] ?? '';
                                final date = appointment['date'] ?? '';
                                final time = appointment['timeSlot'] ?? '';
                                await NotificationService().saveNotificationToFirestore(
                                  userId: patientId,
                                  title: 'Appointment Rejected',
                                  message: 'Your appointment with Dr. $doctorName on $date at $time has been rejected.',
                                  appointmentId: appointmentId,
                                  status: 'rejected',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Appointment rejected and patient notified.')),
                                  );
                                }
                              }
                            },
                            child: const Text('Reject'),
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
} 