import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safarigo/register_screen.dart'; // Import RegisterScreen
import 'package:safarigo/edit_profile_screen.dart'; // Import EditProfileScreen
// Import PaymentScreen
import 'package:safarigo/notification_screen.dart'; // Import NotificationScreen
import 'package:safarigo/bookings_screen.dart'; // Import BookingsScreen
import 'package:safarigo/help_support_screen.dart'; // Import HelpSupportScreen
import 'package:safarigo/user_profile_screen.dart'; // Import UserProfileScreen
// Import DebugUsersScreen
// Import AdminDashboardScreen
import 'main.dart'; // For themeModeNotifier

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _user?.photoURL != null
                              ? NetworkImage(_user!.photoURL!)
                              : AssetImage('assets/avatar.png') as ImageProvider,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: _user?.photoURL == null && _user?.email == null
                              ? Icon(Icons.person, size: 50, color: theme.iconTheme.color)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.displayName ?? (_user?.email?.split('@')[0] ?? 'Guest'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'N/A',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Account Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                         Icon(Icons.dark_mode, color: theme.iconTheme.color),
                         const SizedBox(width: 8),
                         Text('Dark Mode', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
                        ],
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeModeNotifier,
                        builder: (context, mode, _) {
                          return Switch(
                            value: mode == ThemeMode.dark,
                            onChanged: (val) {
                              themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                            },
                           activeColor: theme.colorScheme.primary,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(context, Icons.person, 'View Profile', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
                  }),
                  _buildSettingsTile(context, Icons.edit, 'Edit Profile', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                  }),
                  _buildSettingsTile(context, Icons.payment, 'Payment Methods', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                  }),
                  _buildSettingsTile(context, Icons.notifications, 'Notifications', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                  }),
                  _buildSettingsTile(context, Icons.help_outline, 'Help & Support', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                  }),
                  _buildSettingsTile(context, Icons.history, 'Trip History', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingsScreen()));
                  }),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 2,
                       ),
                       child: const Text('Logout'),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );
   }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: theme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: theme.iconTheme.color),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
} 