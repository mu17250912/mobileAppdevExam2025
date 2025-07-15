import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'user/user_dashboard.dart';
import 'admin/admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    final role = await AuthService().getCurrentUserRole();
    setState(() {
      _role = role;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_role == 'admin') {
      return AdminDashboard();
    }
    return UserDashboard();
  }
} 