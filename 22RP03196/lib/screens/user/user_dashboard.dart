import 'package:flutter/material.dart';
import 'workouts_screen.dart';
import 'progress_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    _DashboardHome(),
    WorkoutsScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().user,
      builder: (context, userSnap) {
        if (!userSnap.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final user = userSnap.data!;
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF22A6F2),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Workouts'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}

class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A3365),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('FITINITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('Welcome Back!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF1A3365))),
            SizedBox(height: 8),
            Text('Push yourself!\nBecause no one else is going to do it for you.', style: TextStyle(fontSize: 16, color: Color(0xFF1A3365).withOpacity(0.7))),
            SizedBox(height: 28),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    _FeatureIconButton(
                      icon: Icons.person,
                      label: 'Profile',
                      color: Color(0xFF1A3365),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.calendar_month,
                      label: 'Plans',
                      color: Color(0xFF1A3365),
                      onTap: () => Navigator.pushNamed(context, '/plans'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      color: Colors.redAccent,
                      onTap: () => Navigator.pushNamed(context, '/favorites_workouts'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.groups,
                      label: 'Areas',
                      color: Color(0xFF1A3365),
                      onTap: () => Navigator.pushNamed(context, '/areas'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.star,
                      label: 'Go Premium',
                      color: Colors.amber[800]!,
                      onTap: () => Navigator.pushNamed(context, '/go_premium'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.bar_chart,
                      label: 'Stats',
                      color: Color(0xFF1A3365),
                      onTap: () => Navigator.pushNamed(context, '/notifications_stats'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.directions_run,
                      label: 'Workout Step',
                      color: Color(0xFF1A3365),
                      onTap: () => Navigator.pushNamed(context, '/workout_step'),
                    ),
                    _FeatureIconButton(
                      icon: Icons.school,
                      label: 'Book Trainer',
                      color: Colors.green,
                      onTap: () => Navigator.pushNamed(context, '/book_trainer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureIconButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 140,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF1A3365),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 