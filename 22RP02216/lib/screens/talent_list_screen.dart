import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'talent_detail_screen.dart';

class TalentListScreen extends StatelessWidget {
  const TalentListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Browse Talents',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'talent')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No talents found.',
                style: GoogleFonts.poppins(color: Colors.deepPurple),
              ),
            );
          }
          final talents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final talent = snapshot.data!.docs[index];
              final data = talent.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12,
                ),
                child: Material(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundImage:
                          (data['photoUrl'] != null &&
                              (data['photoUrl'] as String).isNotEmpty)
                          ? NetworkImage(data['photoUrl'])
                          : const AssetImage('assets/default_avatar.jpg')
                                as ImageProvider,
                      backgroundColor: Colors.grey[200],
                    ),
                    title: Text(
                      data['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${data['talentType'] ?? ''} • ${data['price'] ?? ''} RWF',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.deepPurple,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TalentDetailScreen(talentData: data),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
