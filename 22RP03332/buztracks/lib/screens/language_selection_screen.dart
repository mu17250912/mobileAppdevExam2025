import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final void Function(Locale) onLanguageSelected;
  final Locale? currentLocale;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
    this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isFrench 
          ? AppLocalizations.of(context)!.selectLanguage 
          : 'Select Language'),
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
              mainColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.language,
                      size: 64,
                      color: mainColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFrench 
                        ? AppLocalizations.of(context)!.selectLanguage 
                        : 'Select Language',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFrench 
                        ? 'Choisissez votre langue préférée'
                        : 'Choose your preferred language',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Language Options
              Expanded(
                child: Column(
                  children: [
                    // English Option
                    _buildLanguageCard(
                      context: context,
                      locale: const Locale('en'),
                      flag: '🇺🇸',
                      languageName: 'English',
                      nativeName: 'English',
                      isSelected: currentLocale?.languageCode == 'en',
                      onTap: () => onLanguageSelected(const Locale('en')),
                    ),
                    const SizedBox(height: 16),
                    
                    // French Option
                    _buildLanguageCard(
                      context: context,
                      locale: const Locale('fr'),
                      flag: '🇫🇷',
                      languageName: 'French',
                      nativeName: 'Français',
                      isSelected: currentLocale?.languageCode == 'fr',
                      onTap: () => onLanguageSelected(const Locale('fr')),
                    ),
                  ],
                ),
              ),
              
              // Current Selection Info
              if (currentLocale != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mainColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: mainColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isFrench 
                            ? 'Langue actuelle: ${currentLocale!.languageCode == 'en' ? 'English' : 'Français'}'
                            : 'Current language: ${currentLocale!.languageCode == 'en' ? 'English' : 'French'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required Locale locale,
    required String flag,
    required String languageName,
    required String nativeName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color mainColor = const Color(0xFFFFD600);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? mainColor.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? mainColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            
            // Language Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? mainColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nativeName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: mainColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
} 