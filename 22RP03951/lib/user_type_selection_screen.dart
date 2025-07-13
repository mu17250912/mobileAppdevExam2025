import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'user_provider.dart';
import 'home_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedUserType;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'type': 'Farmer',
      'title': 'Farmer',
      'description': 'Sell your agricultural products directly to buyers',
      'icon': Icons.agriculture,
      'color': Colors.green,
    },
    {
      'type': 'Buyer',
      'title': 'Buyer',
      'description': 'Purchase fresh products directly from farmers',
      'icon': Icons.shopping_cart,
      'color': Colors.blue,
    },
    {
      'type': 'Admin',
      'title': 'Administrator',
      'description': 'Manage the platform and oversee operations',
      'icon': Icons.admin_panel_settings,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to AgriConnect!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select your role to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // User Type Options
              Expanded(
                child: ListView.builder(
                  itemCount: _userTypes.length,
                  itemBuilder: (context, index) {
                    final userType = _userTypes[index];
                    final isSelected = _selectedUserType == userType['type'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: isSelected ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected 
                          ? BorderSide(color: userType['color'], width: 2)
                          : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedUserType = userType['type'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: userType['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  userType['icon'],
                                  color: userType['color'],
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userType['title'],
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? userType['color'] : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userType['description'],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: userType['color'],
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUserType == null || _isLoading 
                    ? null 
                    : _continueWithUserType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueWithUserType() async {
    if (_selectedUserType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUserType(_selectedUserType!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 