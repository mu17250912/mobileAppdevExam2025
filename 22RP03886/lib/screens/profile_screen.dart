import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  final _nameController = TextEditingController();
  bool _editingName = false;
  bool _savingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.userProfile;
          if (user == null) {
            return Center(child: Text('No user info available.'));
          }
          _nameController.text = user.displayName ?? '';
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, size: 48, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 16),
                  // Editable Name
                  _editingName
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(labelText: 'Display Name'),
                              ),
                            ),
                            _savingName
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                      setState(() => _savingName = true);
                                      await Provider.of<UserProvider>(context, listen: false)
                                          .updateProfile(
                                            firstName: _nameController.text.trim().split(' ').first,
                                            lastName: _nameController.text.trim().split(' ').length > 1 
                                                ? _nameController.text.trim().split(' ').skip(1).join(' ')
                                                : null,
                                          );
                                      setState(() {
                                        _editingName = false;
                                        _savingName = false;
                                      });
                                    },
                                  ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() => _editingName = false);
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.displayName ?? 'No Name',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 20),
                              onPressed: () {
                                setState(() => _editingName = true);
                              },
                            ),
                          ],
                        ),
                  SizedBox(height: 8),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dark Mode', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _isDarkMode,
                        onChanged: (val) {
                          setState(() => _isDarkMode = val);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Subscription status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.isSubscribed
                            ? (user.subscriptionPlan == 'trial'
                                ? 'Free Trial: ${userProvider.remainingTrialDays ?? 0} days left'
                                : 'Subscribed: ${user.subscriptionPlan ?? "Unknown"} (expires: ${user.subscriptionExpiry?.toLocal().toString().split(" ")[0] ?? "-"})')
                            : 'Not Subscribed',
                        style: TextStyle(fontSize: 16, color: userProvider.isSubscribed ? Colors.green : Colors.red),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                            );
                          },
                          child: Text('Manage Subscription'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Provider.of<UserProvider>(context, listen: false).signOut();
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Log Out', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<UserProvider>(context, listen: false)
                  .changePassword(_passwordController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password changed successfully!')),
              );
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }
} 