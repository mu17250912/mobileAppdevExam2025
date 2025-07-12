import 'package:flutter/material.dart';
import '../config/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _vatRateController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.userProfile != null) {
      _nameController.text = appState.userProfile!.name;
      _emailController.text = appState.userProfile!.email;
      _businessNameController.text = appState.userProfile!.businessName ?? '';
      _vatRateController.text = '${(appState.userProfile!.defaultVATRate * 100).toStringAsFixed(0)}%';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    setState(() {
      _loading = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.updateProfile(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.logout();
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isPremium = appState.userProfile?.premium ?? false;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Settings', style: AppTypography.titleMedium),
      ),
      body: appState.userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.green100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(appState.userProfile!.name, style: AppTypography.titleLarge),
                        Text(appState.userProfile!.email, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profile Information', style: AppTypography.titleMedium),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabled: false, // Email cannot be changed
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: 'Business Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Default Settings', style: AppTypography.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Default VAT Rate', style: AppTypography.bodyMedium),
                              SizedBox(
                                width: 64,
                                child: TextFormField(
                                  controller: _vatRateController,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelLarge,
                      ),
                      onPressed: _loading ? null : _saveChanges,
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isPremium)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.verified, color: Colors.amber.shade700),
                        label: const Text('You are Premium!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: AppTypography.labelLarge,
                        ),
                        onPressed: null, // Disabled
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.star, color: Colors.amber.shade700),
                        label: const Text('Upgrade to Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: AppTypography.labelLarge,
                        ),
                        onPressed: () async {
                          final url = Uri.parse('https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_xclick&business=ivancyusa1@gmail.com&amount=5&currency_code=USD&item_name=QuickDocs+Premium');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open PayPal link.')),
                            );
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                      label: const Text('Refresh Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelLarge,
                      ),
                      onPressed: () async {
                        final appState = Provider.of<AppState>(context, listen: false);
                        await appState.refreshUserProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile refreshed!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red50,
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelLarge,
                      ),
                      onPressed: _showLogoutConfirmation,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline, color: AppColors.primary),
                      label: const Text('About QuickDocs'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelLarge,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () => context.go('/about'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 