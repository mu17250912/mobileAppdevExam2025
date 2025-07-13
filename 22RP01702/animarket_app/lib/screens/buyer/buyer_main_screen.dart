import 'package:flutter/material.dart';
import 'buyer_dashboard.dart';
import 'notifications_screen.dart';
import 'profile_settings_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class BuyerMainScreen extends StatefulWidget {
  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    BuyerDashboard(),
    NotificationsScreen(),
    ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        isSeller: false,
      ),
    );
  }
}
