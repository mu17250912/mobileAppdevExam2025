import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TalentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> talentData;
  const TalentDetailScreen({Key? key, required this.talentData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        title: Text(
          'Talent Details',
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        (talentData['photoUrl'] != null &&
                            (talentData['photoUrl'] as String).isNotEmpty)
                        ? NetworkImage(talentData['photoUrl'])
                        : const AssetImage('assets/default_avatar.jpg')
                              as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  talentData['name'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  talentData['talentType'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: ${talentData['price'] ?? ''} RWF',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 8),
                // More Information Section
                Card(
                  color: Colors.deepPurple.withOpacity(0.04),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.deepPurple.withOpacity(0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More Information',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (talentData['moreInfo'] ?? '').isNotEmpty
                              ? talentData['moreInfo']
                              : 'No additional information provided.',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final phone = talentData['contact'] ?? '';
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Text(
                    'Contact: ${talentData['contact'] ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingFormScreen(talentData: talentData),
                        ),
                      );
                    },
                    child: Text(
                      'Book',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
