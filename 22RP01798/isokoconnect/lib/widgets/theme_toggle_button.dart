import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeToggleButton extends StatefulWidget {
  final double? size;
  final Color? iconColor;

  const ThemeToggleButton({
    Key? key,
    this.size,
    this.iconColor,
  }) : super(key: key);

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: IconButton(
                icon: Icon(
                  _getThemeIcon(themeService.themeMode),
                  size: widget.size ?? 24,
                  color: widget.iconColor ?? Theme.of(context).appBarTheme.foregroundColor,
                ),
                tooltip: 'Current: ${themeService.themeModeName}\nTap to cycle themes',
                onPressed: () {
                  _cycleTheme(themeService);
                  _animationController.forward().then((_) {
                    _animationController.reset();
                  });
                },
              ),
            );
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

  void _cycleTheme(ThemeService themeService) {
    switch (themeService.themeMode) {
      case ThemeMode.light:
        themeService.setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        themeService.setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        themeService.setThemeMode(ThemeMode.light);
        break;
    }
  }
} 