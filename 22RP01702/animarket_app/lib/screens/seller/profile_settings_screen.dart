import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/edit_profile_screen.dart';
import '../auth/login_screen.dart';

class SellerProfileSettingsScreen extends StatelessWidget {
  Future<void> _openPayPal(BuildContext context) async {
    final url = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_xclick&business=sb-1nl2m43920092@business.example.com&amount=10&currency_code=USD&item_name=Premium+Upgrade';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PayPal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Profile'),
        backgroundColor: Colors.green,
        actions: [
          // Edit profile icon
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditProfileScreen(),
              ));
            },
          ),
          // Premium icon/button
          if (user != null && user.isPremium)
            Row(
              children: [
                Icon(Icons.verified, color: Colors.amber, size: 32),
                SizedBox(width: 4),
                Text('Premium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
              ],
            )
          else
            TextButton.icon(
              icon: Icon(Icons.star_border, color: Colors.amber, size: 28),
              label: Text('Premium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
              onPressed: () => _openPayPal(context),
            ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, size: 64, color: Colors.blue),
              ),
            ),
            SizedBox(height: 24),
            Text('Name', style: TextStyle(color: Colors.grey)),
            Text(user?.name ?? '', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Phone', style: TextStyle(color: Colors.grey)),
            Text(user?.phone ?? '', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Location', style: TextStyle(color: Colors.grey)),
            Text(user?.location ?? '', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Role', style: TextStyle(color: Colors.grey)),
            Text(user?.role?.toString().split('.').last ?? '', style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            if (user != null && user.isPremium)
              Center(
                child: Text(
                  'You are a premium user!',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 