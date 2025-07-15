import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/isoko_app_bar.dart';
import '../widgets/app_menu.dart';
import '../widgets/theme_switcher.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userRole;

  const ProfileScreen({
    Key? key,
    required this.userRole,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        final userData = await _firestoreService.getUserData(currentUser.uid);
        if (userData != null) {
          setState(() {
            _userData = userData;
            _phoneController.text = userData['phone'] ?? '';
            _districtController.text = userData['district'] ?? '';
            _sectorController.text = userData['sector'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        await _firestoreService.updateUserProfile(currentUser.uid, {
          'phone': _phoneController.text.trim(),
          'district': _districtController.text.trim(),
          'sector': _sectorController.text.trim(),
        });
        
        setState(() => _isEditing = false);
        await _loadUserData(); // Reload data
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Failed to load profile data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green[100],
                              child: Icon(
                                widget.userRole == 'Seller' ? Icons.agriculture : 
                                widget.userRole == 'Admin' ? Icons.admin_panel_settings : Icons.shopping_basket,
                                size: 50,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userData!['fullName'] ?? 'Unknown',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.userRole,
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Profile Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Personal Information',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _isEditing = !_isEditing),
                                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                                    color: Colors.green[700],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.email_outlined, 'Email', _userData!['email'] ?? 'N/A', false),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.phone_outlined, 'Phone', _userData!['phone'] ?? 'N/A', _isEditing, controller: _phoneController),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.location_city_outlined, 'District', _userData!['district'] ?? 'N/A', _isEditing, controller: _districtController),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.map_outlined, 'Sector', _userData!['sector'] ?? 'N/A', _isEditing, controller: _sectorController),
                              if (_isEditing) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Theme Settings
                      const ThemeSwitcher(),
                      const SizedBox(height: 24),
                      
                      // Actions
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Actions',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: Icon(Icons.logout, color: Colors.red[600]),
                                title: const Text('Logout'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                                onTap: () => _showLogoutDialog(context),
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

  Widget _buildInfoRow(IconData icon, String label, String value, bool isEditing, {TextEditingController? controller}) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              if (isEditing && controller != null)
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    border: const UnderlineInputBorder(),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
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
                await _authService.signOut();
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

  @override
  void dispose() {
    _phoneController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    super.dispose();
  }
} 