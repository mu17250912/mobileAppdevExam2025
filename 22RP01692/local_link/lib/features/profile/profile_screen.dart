import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_appbar.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../debug/log_viewer_screen.dart';
import '../debug/performance_dashboard_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    logger.info('ProfileScreen initialized');
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    logger.debug('Loading user profile', 'ProfileScreen');
    // Get current user from auth service
    _firebaseUser = _authService.currentUser;
    
    if (_firebaseUser != null) {
      // Load user data from Firestore
      _userData = await _authService.getUserData(_firebaseUser!.uid);
      logger.info('User profile loaded: ${_firebaseUser!.email}', 'ProfileScreen');
    } else {
      logger.debug('No user logged in', 'ProfileScreen');
    }
    
    setState(() {});
  }

  void _showLoginDialog() {
    logger.debug('Showing login dialog', 'ProfileScreen');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to access your profile and book services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile() {
    if (_firebaseUser == null) {
      _showLoginDialog();
      return;
    }
    
    logger.debug('Edit profile requested', 'ProfileScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _logout() {
    logger.info('Logout requested', 'ProfileScreen');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pop(context);
              _loadUserProfile();
              logger.info('User logged out successfully', 'ProfileScreen');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openLogViewer() {
    logger.info('Opening log viewer', 'ProfileScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerScreen()),
    );
  }

  void _openPerformanceDashboard() {
    logger.info('Opening performance dashboard', 'ProfileScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PerformanceDashboardScreen()),
    );
  }

  void _testLogging() {
    logger.debug('This is a debug message', 'Test');
    logger.info('This is an info message', 'Test');
    logger.warning('This is a warning message', 'Test');
    logger.error('This is an error message', 'Test', Exception('Test exception'));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test logs added! Check the log viewer.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _firebaseUser == null;
    final isLoading = _firebaseUser != null && _userData == null;
    final theme = Theme.of(context);
    
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Profile',
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Profile Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFF667EEA), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.blue.withOpacity(0.08),
                            child: Text(
                              isGuest ? 'G' : (_userData?['name'] ?? _firebaseUser!.email!.substring(0, 1)).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          isGuest ? 'Guest User' : (_userData?['name'] ?? _firebaseUser!.email!.split('@')[0]),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isGuest ? 'guest@example.com' : (_firebaseUser!.email ?? ''),
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                        ),
                        if (!isGuest && (_userData?['isVerified'] ?? false))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.green[600], size: 22),
                                const SizedBox(width: 4),
                                const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 22),
                        if (isGuest)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/auth'),
                            icon: const Icon(Icons.login),
                            label: const Text('Login / Register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _showEditProfile,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Profile Info Cards
                  _buildInfoCard(
                    'Phone',
                    isGuest ? 'Not provided' : (_userData?['phone'] ?? 'Not provided'),
                    Icons.phone,
                    isGuest ? null : () => _showEditProfile(),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoCard(
                    'Address',
                    isGuest ? 'Not provided' : (_userData?['address'] ?? 'Not provided'),
                    Icons.location_on,
                    isGuest ? null : () => _showEditProfile(),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoCard(
                    'Email',
                    isGuest ? 'Not provided' : (_firebaseUser!.email ?? 'Not provided'),
                    Icons.email,
                    null,
                  ),
                  const SizedBox(height: 32),
                  // Debug Menu (only show in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Debug Tools',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildActionTile('View Logs', Icons.article, _openLogViewer),
                        const SizedBox(height: 14),
                        _buildActionTile('Performance Dashboard', Icons.speed, _openPerformanceDashboard),
                        const SizedBox(height: 14),
                        _buildActionTile('Test Logging', Icons.bug_report, _testLogging),
                        const SizedBox(height: 14),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, VoidCallback? onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(value),
        trailing: onTap != null ? const Icon(Icons.edit, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, bool value, Function(bool) onChanged) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
} 