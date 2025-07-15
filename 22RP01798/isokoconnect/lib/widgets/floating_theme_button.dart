import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class FloatingThemeButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const FloatingThemeButton({
    Key? key,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return FloatingActionButton(
          heroTag: 'theme_toggle',
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          mini: true,
          child: Icon(
            _getThemeIcon(themeService.themeMode),
            size: size ?? 20,
          ),
          tooltip: 'Switch Theme (${themeService.themeModeName})',
          onPressed: () {
            _showThemeDialog(context, themeService);
          },
        );
      },
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
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
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: () {
        themeService.setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }
} 