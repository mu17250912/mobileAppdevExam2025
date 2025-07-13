import 'package:flutter/material.dart';
import '../../widgets/isoko_app_bar.dart';
import '../../widgets/app_menu.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreService _firestoreService = FirestoreService();

  void _showUserForm({UserModel? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final districtController = TextEditingController(text: user?.district ?? '');
    final sectorController = TextEditingController(text: user?.sector ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final role = ValueNotifier<String>(user?.role ?? 'Seller');
    final isPremium = ValueNotifier<bool>(user?.isPremium ?? false);
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
                ),
                TextFormField(
                  controller: districtController,
                  decoration: const InputDecoration(labelText: 'District'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter district' : null,
                ),
                TextFormField(
                  controller: sectorController,
                  decoration: const InputDecoration(labelText: 'Sector'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter sector' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                ),
                if (!isEdit)
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                    obscureText: true,
                  ),
                ValueListenableBuilder<String>(
                  valueListenable: role,
                  builder: (context, value, _) => DropdownButtonFormField<String>(
                    value: value,
                    items: const [
                      DropdownMenuItem(value: 'Seller', child: Text('Seller')),
                      DropdownMenuItem(value: 'Buyer', child: Text('Buyer')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => role.value = v ?? 'Seller',
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isPremium,
                  builder: (context, value, _) => CheckboxListTile(
                    value: value,
                    onChanged: (v) => isPremium.value = v ?? false,
                    title: const Text('Premium User'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newUser = UserModel(
                id: isEdit ? user!.id : emailController.text.trim(),
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                district: districtController.text.trim(),
                sector: sectorController.text.trim(),
                role: role.value,
                email: emailController.text.trim(),
                isPremium: isPremium.value,
              );
              try {
                if (isEdit) {
                  await _firestoreService.updateUser(newUser);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated.')));
                } else {
                  await _firestoreService.createUser(newUser, passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created.')));
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteUser(user.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted.')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _changeUserRole(UserModel user) {
    final role = ValueNotifier<String>(user.role);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.fullName}'),
        content: ValueListenableBuilder<String>(
          valueListenable: role,
          builder: (context, value, _) => DropdownButtonFormField<String>(
            value: value,
            items: const [
              DropdownMenuItem(value: 'Seller', child: Text('Seller')),
              DropdownMenuItem(value: 'Buyer', child: Text('Buyer')),
              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
            ],
            onChanged: (v) => role.value = v ?? user.role,
            decoration: const InputDecoration(labelText: 'Role'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.changeUserRole(user.id, role.value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated.')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: IsokoAppBar(
        title: 'Manage Users',
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: AppMenu(
        userRole: 'Admin',
        onHomePressed: () => Navigator.pop(context),
        onProductsPressed: () => Navigator.pop(context),
        onProfilePressed: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading users'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(child: Text('No users found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?')),
                title: Text(user.fullName),
                subtitle: Text('${user.email}\nRole: ${user.role}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () => _showUserForm(user: user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeleteUser(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      tooltip: 'Change Role',
                      onPressed: () => _changeUserRole(user),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 