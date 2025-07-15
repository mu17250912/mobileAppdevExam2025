import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/comedian.dart';
import 'comedian_profile.dart';
import 'comedy_shorts.dart';
import 'login_page.dart'; // Added import for LoginPage
import 'book_ticket_page.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'user_profile.dart'; // Corrected import for UserProfilePage
import 'package:url_launcher/url_launcher.dart'; // Added import for url_launcher
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;

final comedians = [
  Comedian(
    name: 'Rusine',
    bio: 'Rusine is a celebrated Rwandan comedian known for his witty humor and relatable performances.',
    rating: 4.9,
    imageUrl: '', // Will use assets/rusine.png in profile
  ),
  Comedian(
    name: 'Muhinde',
    bio: 'Muhinde is a talented comedian whose energetic stage presence and clever jokes have won the hearts of many.',
    rating: 4.8,
    imageUrl: '', // Will use assets/muhinde.png in profile
  ),
  // New comedians
  Comedian(
    name: 'Umushumba',
    bio: 'Umushumba is known for his sharp wit and insightful social commentary, making audiences laugh and think.',
    rating: 4.7,
    imageUrl: 'assets/umushumba.png',
  ),
  Comedian(
    name: 'Umunyamulenge',
    bio: 'Umunyamulenge brings a unique cultural perspective to comedy, blending humor with powerful storytelling.',
    rating: 4.6,
    imageUrl: 'assets/umunyamulenge.png',
  ),
  Comedian(
    name: 'Dr Nsabi',
    bio: 'Dr Nsabi is a master of satire and parody, delighting audiences with clever jokes and memorable performances.',
    rating: 4.8,
    imageUrl: 'assets/nsabi.png',
  ),
];

// Global notifications list
List<Map<String, dynamic>> notifications = [];

class Dashboard extends StatelessWidget {
  final User user;
  const Dashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: fb_auth.FirebaseAuth.instance.currentUser == null
                ? null
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(fb_auth.FirebaseAuth.instance.currentUser!.uid)
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              int notifCount = 0;
              if (snapshot.hasData) {
                notifCount = snapshot.data!.docs.length;
              }
              return badges.Badge(
                showBadge: notifCount > 0,
                badgeContent: Text(
                  notifCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                position: badges.BadgePosition.topEnd(top: -8, end: -8),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Colors.red,
                  padding: const EdgeInsets.all(6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: () {
                    final user = fb_auth.FirebaseAuth.instance.currentUser;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Notifications'),
                        content: user == null
                            ? const Text('Please log in to see notifications')
                            : SizedBox(
                                width: 350,
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('notifications')
                                      .orderBy('timestamp', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final docs = snapshot.data!.docs;
                                    if (docs.isEmpty) {
                                      return const Text('No new notifications');
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final n = docs[index].data() as Map<String, dynamic>;
                                        final notifId = docs[index].id;
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          child: ListTile(
                                            leading: const Icon(Icons.notifications),
                                            title: Text(
                                              '${n['ticketType']} Ticket x${n['ticketCount']} - ${n['paymentMethod']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Total Paid: ${n['total']} RWF'),
                                                if (n['paymentMethod'] == 'PayPal')
                                                  Text('Email: ${n['email']}'),
                                                if (n['paymentMethod'] == 'MTN' || n['paymentMethod'] == 'Airtel')
                                                  Text('Phone: ${n['phone']}'),
                                                Text('Booking Code: ${n['bookingCode']}'),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Delete',
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(user.uid)
                                                    .collection('notifications')
                                                    .doc(notifId)
                                                    .delete();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F5BD5), Color(0xFF6A82FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple[100],
                    radius: 32,
                    child: Icon(Icons.person, color: Colors.deepPurple, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.username,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Just close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.deepPurple),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_num, color: Colors.deepPurple),
              title: const Text('Book Ticket'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookTicketPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FFAE), // Light yellow
              Color(0xFF43E97B), // Green
              Color(0xFF38F9D7), // Aqua
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Welcome Section
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  radius: 28,
                  child: Icon(Icons.person, color: Colors.deepPurple, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Welcome, ${user.username}!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookTicketPage()),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        color: Colors.white, // or Colors.grey[200]
                        child: Image.asset(
                          'assets/event.png',
                          height: 320, // Try 120, 140, or 150 to see what looks best
                          width: double.infinity,
                          fit: BoxFit.contain, // Show the whole image, not cropped
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          Text(
                            'Book Regular Ticket',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reserve your spot for the next big comedy event!',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Comedian Profiles
            Text('Comedian Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple[700])),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: comedians.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final comedian = comedians[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ComedianProfile(comedian: comedian)),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: comedian.imageUrl.isNotEmpty
                                  ? AssetImage(comedian.imageUrl)
                                  : comedian.name.toLowerCase() == 'rusine'
                                      ? const AssetImage('assets/rusine.png')
                                      : comedian.name.toLowerCase() == 'muhinde'
                                          ? const AssetImage('assets/muhinde.png')
                                          : null,
                              radius: 28,
                              child: comedian.imageUrl.isEmpty &&
                                      comedian.name.toLowerCase() != 'rusine' &&
                                      comedian.name.toLowerCase() != 'muhinde'
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comedian.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text('${comedian.rating}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Comedy Shorts
            Text('Comedy Shorts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple[700])),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                title: Text('Watch Comedy Shorts', style: TextStyle(color: Colors.deepPurple[700])),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ComedyShorts()),
                  );
                },
              ),
            ),
            // Partner Banner Ad
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.15)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Promote your business with Facebook Audience Network!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Special Offer'),
                                content: const Text(
                                  'Get exclusive access to Facebook Audience Network promotions and boost your business reach! Contact us for partnership opportunities or click below to learn more.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      const url = 'https://www.facebook.com/audiencenetwork/';
                                      try {
                                        final Uri uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open partner link')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error opening link: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Learn More'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Special Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () async {
                            const url = 'https://www.facebook.com/audiencenetwork/';
                            try {
                              final Uri uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open partner link')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening link: $e')),
                              );
                            }
                          },
                          child: const Text('Learn More >', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        const url = 'https://www.facebook.com/audiencenetwork/';
                        try {
                          final Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open partner link')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error opening link: $e')),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/advertise.png',
                          fit: BoxFit.contain,
                          height: 80,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Second Partner Banner Ad (Alibaba)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.15)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Discover millions of business offerings on Alibaba.com!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Special Offer'),
                                content: const Text(
                                  'Explore products and suppliers for your business from millions of offerings worldwide. Enjoy exclusive discounts and order protections on Alibaba.com!',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      const url = 'https://www.alibaba.com';
                                      try {
                                        final Uri uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open partner link')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error opening link: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Learn More'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Special Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () async {
                            const url = 'https://www.alibaba.com';
                            try {
                              final Uri uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open partner link')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening link: $e')),
                              );
                            }
                          },
                          child: const Text('Learn More >', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        const url = 'https://www.alibaba.com';
                        try {
                          final Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open partner link')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error opening link: $e')),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/alibaba.png',
                          fit: BoxFit.contain,
                          height: 80,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 