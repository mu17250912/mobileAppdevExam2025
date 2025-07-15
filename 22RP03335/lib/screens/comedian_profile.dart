import 'package:flutter/material.dart';
import '../models/comedian.dart';
import 'dart:ui';

class ComedianProfile extends StatelessWidget {
  final Comedian comedian;
  const ComedianProfile({super.key, required this.comedian});

  @override
  Widget build(BuildContext context) {
    String description =
        'A renowned comedian known for their unique style and humor. Has performed in various countries and won several awards.';
    String historicalBackground =
        'Started their career in local clubs before rising to national fame. Their journey is marked by perseverance, creativity, and a passion for making people laugh.';
    ImageProvider? profileImage;
    String catchPhrase = 'Keep Smiling!';
    List<Color> bgGradient = [
      const Color(0xFF4F5BD5), // Muted blue
      const Color(0xFF6A82FB), // Soft indigo
    ];
    if (comedian.name.toLowerCase() == 'rusine') {
      profileImage = const AssetImage('assets/rusine.png');
      description = 'Rusine is a celebrated Rwandan comedian known for his witty humor and relatable performances. He has been a staple in the comedy scene, inspiring many with his unique perspective and delivery.';
      historicalBackground = 'Rusine began his comedy journey in Kigali, performing at local venues before gaining national recognition. His career is marked by numerous awards and a commitment to uplifting the Rwandan comedy industry.';
      catchPhrase = 'Laughter is the best medicine!';
      bgGradient = [const Color(0xFF4F5BD5), const Color(0xFF6A82FB)];
    } else if (comedian.name.toLowerCase() == 'muhinde') {
      profileImage = const AssetImage('assets/muhinde.png');
      description = 'Muhinde is a talented comedian whose energetic stage presence and clever jokes have won the hearts of many. He is known for his improvisational skills and engaging storytelling.';
      historicalBackground = 'Muhinde started performing comedy in university clubs and quickly rose to fame through viral social media skits. He continues to inspire young comedians across the country.';
      catchPhrase = 'Let the good times roll!';
      bgGradient = [const Color(0xFF11998e), const Color(0xFF38ef7d)]; // Teal to green
    } else if (comedian.name.toLowerCase() == 'umushumba') {
      profileImage = const AssetImage('assets/umushumba.png');
      description = 'Umushumba is known for his sharp wit and insightful social commentary, making audiences laugh and think.';
      historicalBackground = 'Umushumba has performed on many stages, captivating audiences with his unique blend of humor and wisdom.';
      catchPhrase = 'Wisdom with a smile!';
      bgGradient = [const Color(0xFFff9966), const Color(0xFFff5e62)]; // Orange to red
    } else if (comedian.name.toLowerCase() == 'umunyamulenge') {
      profileImage = const AssetImage('assets/umunyamulenge.png');
      description = 'Umunyamulenge brings a unique cultural perspective to comedy, blending humor with powerful storytelling.';
      historicalBackground = 'Umunyamulenge is celebrated for his ability to connect with diverse audiences and share stories that resonate.';
      catchPhrase = 'Stories that make you laugh!';
      bgGradient = [const Color(0xFF56ab2f), const Color(0xFFa8e063)]; // Green gradient
    } else if (comedian.name.toLowerCase() == 'dr nsabi') {
      profileImage = const AssetImage('assets/nsabi.png');
      description = 'Dr Nsabi is a master of satire and parody, delighting audiences with clever jokes and memorable performances.';
      historicalBackground = 'Dr Nsabi has a long career in comedy, known for his sharp mind and unforgettable stage presence.';
      catchPhrase = 'Satire is my medicine!';
      bgGradient = [const Color(0xFF614385), const Color(0xFF516395)]; // Purple gradient
    } else if (comedian.imageUrl.isNotEmpty) {
      if (comedian.imageUrl.startsWith('assets/')) {
        profileImage = AssetImage(comedian.imageUrl);
      } else {
        profileImage = NetworkImage(comedian.imageUrl);
      }
    }

    Widget laughMeter(double rating) {
      int full = rating.floor();
      bool half = (rating - full) >= 0.5;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          if (i < full) {
            return const Icon(Icons.emoji_emotions, color: Colors.deepPurple, size: 24);
          } else if (i == full && half) {
            return const Icon(Icons.emoji_emotions, color: Colors.deepPurpleAccent, size: 24);
          } else {
            return const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 24);
          }
        }),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          comedian.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 1.2),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: profileImage,
                          radius: 54,
                          backgroundColor: Colors.grey[200],
                          child: profileImage == null
                              ? const Icon(Icons.person, size: 54, color: Colors.deepPurple)
                              : null,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          comedian.name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 1.2,
                            fontFamily: 'Roboto',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        laughMeter(comedian.rating),
                        const SizedBox(height: 6),
                        Text(
                          'Laugh Meter',
                          style: TextStyle(
                            color: Colors.deepPurple.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '"$catchPhrase"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Section Cards
                _SectionCard(
                  icon: Icons.info_outline,
                  color: Colors.deepPurple,
                  title: 'Description',
                  text: description,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.history_edu,
                  color: Colors.teal,
                  title: 'Historical Background',
                  text: historicalBackground,
                ),
                if (comedian.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.person,
                    color: Colors.indigo,
                    title: 'Bio',
                    text: comedian.bio,
                  ),
                ],
                const SizedBox(height: 32),
                // Small friendly emoji at the bottom
                const Text('😊', style: TextStyle(fontSize: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _SectionCard({required this.icon, required this.color, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, fontFamily: 'Roboto'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}