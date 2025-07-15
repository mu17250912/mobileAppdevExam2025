import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../screens/auth/login_screen.dart';

class AppMenu extends StatelessWidget {
  final String userRole;
  final VoidCallback? onHomePressed;
  final VoidCallback? onProductsPressed;
  final VoidCallback? onProfilePressed;

  const AppMenu({
    Key? key,
    required this.userRole,
    this.onHomePressed,
    this.onProductsPressed,
    this.onProfilePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    userRole == 'Seller' ? Icons.agriculture : 
                    userRole == 'Admin' ? Icons.admin_panel_settings : Icons.shopping_basket,
                    size: 30,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'IsokoConnect',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userRole,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    onHomePressed?.call();
                  },
                ),
                ListTile(
                  leading: Icon(
                    userRole == 'Seller' ? Icons.inventory : 
                    userRole == 'Admin' ? Icons.inventory : Icons.shopping_basket,
                  ),
                  title: Text(userRole == 'Seller' ? 'My Products' : 'Products'),
                  onTap: () {
                    Navigator.pop(context);
                    onProductsPressed?.call();
                  },
                ),
                if (userRole == 'Seller')
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Manage Orders'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/seller/manage_orders');
                    },
                  ),
                if (userRole == 'Buyer')
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('My Orders'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/buyer/my_orders');
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    onProfilePressed?.call();
                  },
                ),
                const Divider(),
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return ListTile(
                      leading: Icon(
                        themeService.isDarkMode 
                            ? Icons.dark_mode 
                            : themeService.isLightMode 
                                ? Icons.light_mode 
                                : Icons.brightness_auto,
                      ),
                      title: Text('Theme (${themeService.themeModeName})'),
                      onTap: () {
                        Navigator.pop(context);
                        _showThemeDialog(context, themeService);
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(context, themeService, ThemeMode.light, 'Light', Icons.light_mode),
              _buildThemeOption(context, themeService, ThemeMode.dark, 'Dark', Icons.dark_mode),
              _buildThemeOption(context, themeService, ThemeMode.system, 'System', Icons.brightness_auto),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeService themeService, ThemeMode mode, String title, IconData icon) {
    final isSelected = themeService.themeMode == mode;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        themeService.setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.pop(context); // Close drawer
                await AuthService().signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
} 