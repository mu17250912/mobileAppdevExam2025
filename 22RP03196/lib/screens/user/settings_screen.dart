import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _updateName(BuildContext context, AppUser user) async {
    final controller = TextEditingController(text: user.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Name'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': name});
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStream = AuthService().user;
    return Scaffold(
      backgroundColor: const Color(0xFF22A6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22A6F2),
        elevation: 0,
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<AppUser?>(
        stream: userStream,
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final user = snap.data!;
          return ListView(
            padding: EdgeInsets.all(24),
            children: [
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.person, color: const Color(0xFF22A6F2), size: 48),
                      SizedBox(height: 16),
                      Text(user.name ?? user.email, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
                      SizedBox(height: 8),
                      Text(user.email, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Edit Name'),
                        onPressed: () => _updateName(context, user),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              _SettingsCard(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
              SizedBox(height: 18),
              _SettingsCard(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              SizedBox(height: 18),
              _SettingsCard(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  // Show the privacy policy dialog to the user
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Privacy Policy'),
                      content: SingleChildScrollView(
                        child: Text(
                          'We value your privacy. Your data is securely stored and only used to provide personalized fitness services. We do not share your personal information with third parties. You can request data deletion at any time. For more details, contact support.',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF22A6F2), size: 28),
              SizedBox(width: 18),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF22A6F2))),
              Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
} 