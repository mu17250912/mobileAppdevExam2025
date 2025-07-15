import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calculate_bmi_screen.dart';
import 'view_history_screen.dart';
import 'health_tips_screen.dart';
import 'premium_features_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return userDoc.data()?['username'] ?? userDoc.data()?['email'] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF5676EA),
              child: Icon(Icons.person, color: Colors.white),
            ),
            tooltip: 'View Profile',
            onPressed: () async {
              String username = '';
              bool isLoading = true;
              final email = user?.email ?? '';
              // Fetch username from Firestore
              if (user != null) {
                final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                username = doc.data()?['username'] ?? '';
              }
              isLoading = false;
              final usernameController = TextEditingController(text: username);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  bool saving = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFF5676EA),
                              child: Icon(Icons.person, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(email, style: GoogleFonts.montserrat(fontSize: 15, color: Colors.black54)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (saving)
                              const CircularProgressIndicator(),
                            if (!saving)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() => saving = true);
                                      final newUsername = usernameController.text.trim();
                                      if (user != null && newUsername.isNotEmpty) {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'username': newUsername}, SetOptions(merge: true));
                                        // Optionally update displayName in FirebaseAuth
                                        await user.updateDisplayName(newUsername);
                                        setState(() => saving = false);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Username updated!')),
                                        );
                                      } else {
                                        setState(() => saving = false);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5676EA),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Save'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: FutureBuilder<String>(
              future: _fetchUsername(),
              builder: (context, snapshot) {
                final userName = snapshot.data ?? 'User';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${userName.isNotEmpty ? userName : 'User'}!',
                                style: GoogleFonts.montserrat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ready to track your health?',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFB86B), Color(0xFFF57F4A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.transparent,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.bar_chart,
                            title: 'Calculate BMI',
                            subtitle: 'Quick assessment',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5676EA), Color(0xFF7F6AB2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            textColor: Colors.white,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CalculateBMIScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.insert_chart_outlined,
                            title: 'View History',
                            subtitle: 'Past records',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            textColor: const Color(0xFF5676EA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ViewHistoryScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _HorizontalCard(
                      icon: Icons.lightbulb,
                      title: 'Health Tips',
                      subtitle: 'Daily wellness advice',
                      color: Colors.white,
                      iconBg: const Color(0xFFFFD600),
                      titleColor: const Color(0xFF333333),
                      subtitleColor: const Color(0xFF666666),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HealthTipsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _HorizontalCard(
                      icon: Icons.star,
                      title: 'Premium Features',
                      subtitle: 'Unlock advanced tools',
                      color: Colors.white,
                      iconBg: const Color(0xFFFFD700),
                      showNew: true,
                      titleColor: const Color(0xFF333333),
                      subtitleColor: const Color(0xFF666666),
                      badgeColor: const Color(0xFFFFB347),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumFeaturesScreen()),
                        );
                      },
                    ),
                    const Spacer(),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout, color: Color(0xFF5676EA)),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5676EA),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: const Color(0xFF5676EA),
                            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color textColor;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: textColor),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconBg;
  final bool showNew;
  final Color? badgeColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final VoidCallback onTap;
  const _HorizontalCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.iconBg, this.showNew = false, this.badgeColor, this.titleColor, this.subtitleColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor ?? const Color(0xFF22223B),
                        ),
                      ),
                      if (showNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor ?? const Color(0xFFFFB347),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: subtitleColor ?? const Color(0xFF22223B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0C3)),
          ],
        ),
      ),
    );
  }
} 