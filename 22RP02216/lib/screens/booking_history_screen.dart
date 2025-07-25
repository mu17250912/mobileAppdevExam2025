import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingHistoryScreen extends StatelessWidget {
  final bool forTalent;
  const BookingHistoryScreen({Key? key, required this.forTalent})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('BookingHistoryScreen: user.uid = ${user?.uid}');
    debugPrint(
      'BookingHistoryScreen: forTalent = $forTalent, query field = ${forTalent ? 'talentId' : 'clientId'}',
    );
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking History')),
        body: const Center(child: Text('Not logged in.')),
      );
    }
    final query = FirebaseFirestore.instance
        .collection('bookings')
        .where(forTalent ? 'talentId' : 'clientId', isEqualTo: user.uid);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Booking History',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No bookings found.',
                style: GoogleFonts.poppins(color: Colors.deepPurple),
              ),
            );
          }
          final bookings = snapshot.data!.docs;
          debugPrint(
            'BookingHistoryScreen: bookings count = ${bookings.length}',
          );
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = bookings[i].data() as Map<String, dynamic>;
              debugPrint(
                'BookingHistoryScreen: booking data =  {data.toString()}',
              );
              // Defensive: check date format
              final date = data['date'] ?? '';
              final validDate = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);
              if (!validDate) {
                return Card(
                  color: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.error, color: Colors.red, size: 36),
                    title: Text(
                      'Invalid booking date',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      'This booking has an invalid date: $date',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              }
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.event_note,
                    color: Colors.deepPurple,
                    size: 36,
                  ),
                  title: Text(
                    forTalent
                        ? (data['clientEmail'] ?? '')
                        : (data['talentName'] ?? ''),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${data['date'] ?? ''} • ${data['time'] ?? ''}\n${data['eventDetails'] ?? ''}\nStatus: ${data['status'] ?? ''}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Text(
                    '${data['price'] ?? ''} RWF',
                    style: GoogleFonts.poppins(color: Colors.deepPurple),
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
