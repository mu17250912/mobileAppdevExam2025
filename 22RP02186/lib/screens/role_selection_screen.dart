import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'learner_dashboard.dart';
import 'trainer_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String userEmail;
  
  const RoleSelectionScreen({Key? key, required this.userEmail}) : super(key: key);

  Future<void> _handleRoleSelection(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).get();
    if (userQuery.docs.isEmpty) {
      // New user: create user document
      await FirebaseFirestore.instance.collection('users').add({
        'email': userEmail,
        'name': user?.displayName ?? userEmail.split('@')[0],
        'role': role,
        'profileImage': user?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    // Route to dashboard
    if (role == 'learner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LearnerDashboard(userEmail: userEmail)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TrainerDashboard(userEmail: userEmail)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
                'Choose Your Role',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back, ${userEmail.split('@')[0]}!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                context,
                'Learner',
                'I want to learn new skills',
                Icons.school,
                Colors.blue,
                () => _handleRoleSelection(context, 'learner'),
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                context,
                'Trainer',
                'I want to teach and mentor',
                Icons.person,
                Colors.green,
                () => _handleRoleSelection(context, 'trainer'),
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
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
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 