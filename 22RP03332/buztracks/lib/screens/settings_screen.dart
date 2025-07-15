import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'payment_screen.dart';
import 'language_selection_screen.dart';
import 'subscription_screen.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final bool isPremium;
  final VoidCallback? onUpgrade;
  final VoidCallback? onLogout;
  final void Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;
  
  const SettingsScreen({
    super.key, 
    this.isPremium = false, 
    this.onUpgrade,
    this.onLogout,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              mainColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Language Section
            _buildSectionHeader(context, AppLocalizations.of(context)!.language, Icons.language),
            const SizedBox(height: 8),
            _buildLanguageTile(context, isFrench),
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionHeader(context, AppLocalizations.of(context)!.account, Icons.account_circle),
            const SizedBox(height: 8),
            _buildAccountTile(context, isFrench),
            const SizedBox(height: 24),
            
            // Premium Section
            _buildSectionHeader(context, AppLocalizations.of(context)!.premium, Icons.star),
            const SizedBox(height: 8),
            _buildPremiumTile(context, isFrench),
            const SizedBox(height: 24),
            
            // Logout Section
            _buildSectionHeader(context, AppLocalizations.of(context)!.security, Icons.security),
            const SizedBox(height: 8),
            _buildLogoutTile(context, isFrench),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final Color mainColor = const Color(0xFFFFD600);
    
    return Row(
      children: [
        Icon(icon, color: mainColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTile(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);
    final currentLanguage = currentLocale?.languageCode == 'en' ? 'English' : 'Français';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.language, color: mainColor),
        ),
        title: Text(AppLocalizations.of(context)!.language),
        subtitle: Text(
          isFrench 
            ? AppLocalizations.of(context)!.currentLanguage(currentLanguage)
            : 'Current language: $currentLanguage',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LanguageSelectionScreen(
                onLanguageSelected: (locale) {
                  onLanguageChanged?.call(locale);
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFrench 
                          ? AppLocalizations.of(context)!.languageChanged 
                          : 'Language changed successfully',
                      ),
                      backgroundColor: mainColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                currentLocale: currentLocale,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_circle, color: mainColor),
        ),
        title: Text(AppLocalizations.of(context)!.account),
        subtitle: Text(
                      user?.email ?? AppLocalizations.of(context)!.notLoggedIn,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Account management functionality
        },
      ),
    );
  }

  Widget _buildPremiumTile(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPremium ? mainColor : Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPremium ? mainColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.star,
            color: isPremium ? Colors.black : Colors.grey[600],
          ),
        ),
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.premium),
            if (isPremium)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.active,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          isPremium
                          ? AppLocalizations.of(context)!.premiumUserMessage
            : AppLocalizations.of(context)!.freeUserMessage,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: isPremium
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.goPremium,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context, bool isFrench) {
    final Color mainColor = const Color(0xFFFFD600);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.logout, color: Colors.red),
        ),
        title: Text(
          AppLocalizations.of(context)!.logout,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.signOutOfAccount,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                                          child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLogout?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                                          child: Text(AppLocalizations.of(context)!.logout),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
} 