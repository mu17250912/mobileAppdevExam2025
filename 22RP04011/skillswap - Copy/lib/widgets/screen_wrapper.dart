import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class ScreenWrapper extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showBottomNav;
  final Color? backgroundColor;

  const ScreenWrapper({
    super.key,
    required this.child,
    this.title = '',
    this.actions,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.backgroundColor,
  });

  @override
  State<ScreenWrapper> createState() => _ScreenWrapperState();
}

class _ScreenWrapperState extends State<ScreenWrapper> {
  final NavigationService _navigationService = NavigationService();

  @override
  void initState() {
    super.initState();
    _navigationService.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    _navigationService.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              elevation: 0,
              actions: widget.actions,
            )
          : null,
      body: widget.child,
      bottomNavigationBar:
          widget.showBottomNav ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _navigationService.currentIndex,
      onTap: _navigationService.setCurrentIndex,
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: [
        _buildNavItem(Icons.home, 'Home', 0),
        _buildNavItem(Icons.search, 'Search', 1),
        _buildNavItem(Icons.notifications, 'Alerts', 2),
        _buildNavItem(Icons.chat, 'Messenger', 3),
        _buildNavItem(Icons.add_circle_outline, 'Add Skills', 4),
        _buildNavItem(Icons.person, 'Profile', 5),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    final badgeCount = _navigationService.getBadgeCountForTab(index);

    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Icon(icon),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _navigationService.getBadgeText(badgeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}
