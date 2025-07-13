import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:isokoconnect/services/theme_service.dart';
import 'package:isokoconnect/widgets/theme_switcher.dart';

void main() {
  group('Theme Service Tests', () {
    testWidgets('Theme switcher shows all three options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSwitcher(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that all three theme options are present
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('Theme service can switch between themes', (WidgetTester tester) async {
      final themeService = ThemeService();
      
      // Test initial state
      expect(themeService.themeMode, ThemeMode.system);
      
      // Test switching to light mode
      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);
      expect(themeService.isLightMode, true);
      expect(themeService.isDarkMode, false);
      
      // Test switching to dark mode
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);
      expect(themeService.isDarkMode, true);
      expect(themeService.isLightMode, false);
      
      // Test switching back to system
      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeMode, ThemeMode.system);
      expect(themeService.isSystemMode, true);
    });

    testWidgets('Theme mode name is correct', (WidgetTester tester) async {
      final themeService = ThemeService();
      
      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeModeName, 'Light');
      
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeModeName, 'Dark');
      
      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeModeName, 'System');
    });
  });
} 