import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyInternshipDetailPage extends StatelessWidget {
  final String internshipId;
  const CompanyInternshipDetailPage({Key? key, required this.internshipId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              backgroundImage: AssetImage('assets/images/logo.png'),
              child: Icon(Icons.business_center, color: Color(0xFF0D3B24), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Internship Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D3B24),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('internships').doc(internshipId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Internship not found.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(data['title'] ?? 'No Title', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Location: ${data['location'] ?? 'N/A'}'),
                const SizedBox(height: 12),
                Text('Description: ${data['description'] ?? 'N/A'}'),
                const SizedBox(height: 12),
                Text('Posted: ${data['postedDate'] != null ? data['postedDate'].toString() : 'N/A'}'),
                // Add more fields as needed
              ],
            ),
          );
        },
      ),
    );
  }
} 