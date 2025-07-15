import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class RoleSelectionBeforeLogin extends StatelessWidget {
  final VoidCallback? onThemeToggle;
  final ThemeMode? themeMode;
  
  const RoleSelectionBeforeLogin({Key? key, this.onThemeToggle, this.themeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                height: 100,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to SkillsLinks',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose your role to continue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                context,
                'Learner',
                'I want to learn new skills',
                Icons.school,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(userRole: 'learner', onThemeToggle: onThemeToggle, themeMode: themeMode),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                context,
                'Trainer',
                'I want to teach and mentor',
                Icons.person,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(userRole: 'trainer', onThemeToggle: onThemeToggle, themeMode: themeMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? const Color(0xFF23272F) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 