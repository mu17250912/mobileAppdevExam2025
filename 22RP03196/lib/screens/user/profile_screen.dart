import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().user,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF22A6F2),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!;
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF22A6F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    minimumSize: Size(60, 36),
                  ),
                  child: Text('Edit'),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: null, // No profilePic in model
                  child: Icon(Icons.person, size: 48, color: Colors.white),
                  backgroundColor: Colors.blue[200],
                ),
                SizedBox(height: 18),
                Text(user.name ?? user.email, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                SizedBox(height: 6),
                Text(user.email, style: TextStyle(color: Colors.white70)),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.age != null) Text('Age: ${user.age}', style: TextStyle(color: Colors.white)),
                    if (user.age != null) SizedBox(width: 16),
                    if (user.weight != null) Text('Weight: ${user.weight?.toStringAsFixed(0)} lbs', style: TextStyle(color: Colors.white)),
                    if (user.weight != null) SizedBox(width: 16),
                    if (user.height != null) Text('Height: ${user.height?.toStringAsFixed(0)}"', style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(height: 18),
                if (user.fitnessLevel != null) Text('Goal: ${user.fitnessLevel}', style: TextStyle(color: Colors.white)),
                if (user.fitnessLevel == null && user.role != null) Text('Role: ${user.role}', style: TextStyle(color: Colors.white)),
                SizedBox(height: 18),
                if (user.isPremium == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('PREMIUM USER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                if (user.isPremium != true)
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/go_premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      elevation: 2,
                    ),
                    child: Text('GO PREMIUM'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 