import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewHistoryScreen extends StatelessWidget {
  const ViewHistoryScreen({super.key});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _clearAllHistory(BuildContext context, String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bmi_history')
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI History', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All History'),
                    content: const Text('Are you sure you want to delete all BMI history? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _clearAllHistory(context, user.uid);
                }
              },
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
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
        child: user == null
            ? Center(child: Text('Not logged in', style: GoogleFonts.montserrat()))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('bmi_history')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No BMI history yet.', style: GoogleFonts.montserrat(fontSize: 18)),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final bmi = (data['bmi'] as num?)?.toDouble() ?? 0.0;
                      final category = data['category'] as String? ?? '';
                      final date = (data['timestamp'] as Timestamp?)?.toDate();
                      final age = data['age']?.toString();
                      final gender = data['gender']?.toString();
                      final height = data['height']?.toString();
                      final heightUnit = data['heightUnit']?.toString();
                      final weight = data['weight']?.toString();
                      final weightUnit = data['weightUnit']?.toString();
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  bmi.toStringAsFixed(1),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(category),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category == 'Normal' ? 'Normal Weight' : category,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (age != null) ...[
                                        const Icon(Icons.cake, size: 16, color: Color(0xFF5676EA)),
                                        SizedBox(width: 4),
                                        Text('Age: $age', style: GoogleFonts.montserrat(fontSize: 14)),
                                        SizedBox(width: 12),
                                      ],
                                      if (gender != null) ...[
                                        const Icon(Icons.person, size: 16, color: Color(0xFF5676EA)),
                                        SizedBox(width: 4),
                                        Text('Gender: $gender', style: GoogleFonts.montserrat(fontSize: 14)),
                                        SizedBox(width: 12),
                                      ],
                                      if (height != null && heightUnit != null) ...[
                                        const Icon(Icons.height, size: 16, color: Color(0xFF5676EA)),
                                        SizedBox(width: 4),
                                        Text('Height: $height $heightUnit', style: GoogleFonts.montserrat(fontSize: 14)),
                                        SizedBox(width: 12),
                                      ],
                                      if (weight != null && weightUnit != null) ...[
                                        const Icon(Icons.monitor_weight, size: 16, color: Color(0xFF5676EA)),
                                        SizedBox(width: 4),
                                        Text('Weight: $weight $weightUnit', style: GoogleFonts.montserrat(fontSize: 14)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                           IconButton(
                             icon: const Icon(Icons.delete, color: Colors.red),
                             tooltip: 'Delete',
                             onPressed: () async {
                               await docs[i].reference.delete();
                             },
                           ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
} 