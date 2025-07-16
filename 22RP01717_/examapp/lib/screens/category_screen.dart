import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'question_screen.dart';
import 'mock_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';

class CategoryScreen extends StatelessWidget {
  final String userType;
  final bool hasShared;
  CategoryScreen({required this.userType, required this.hasShared});

  final FirestoreService firestoreService = FirestoreService();

  final Map<String, IconData> categoryIcons = {
    'biology': Icons.biotech,
    'chemistry': Icons.science,
    'physics': Icons.flash_on,
    'mathematics': Icons.calculate,
    'math': Icons.calculate,
    'english': Icons.menu_book,
  };

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final sharedPlatforms = userProvider.sharedPlatforms;
    int sharedCount = sharedPlatforms.values.where((v) => v).length;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Categories', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestoreService.getCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final categories = snapshot.data!;
            int unlockedCategories = userType == 'premium'
                ? categories.length
                : sharedCount >= 4 ? 5
                : sharedCount >= 3 ? 4
                : sharedCount >= 2 ? 3
                : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isUnlocked = index < unlockedCategories;
                return GestureDetector(
                  onTap: isUnlocked
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text('Choose Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              content: Text('Do you want to Practice or take a Mock Test?', style: GoogleFonts.poppins()),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionScreen(
                                          category: categories[index]['name'],
                                          numQuestions: 10, // default value
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Practice', style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MockTestScreen(category: categories[index]['name']),
                                      ),
                                    );
                                  },
                                  child: Text('Mock Test', style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }
                      : (index == 2 && userType != 'premium')
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      int sharedCount = sharedPlatforms.values.where((v) => v).length;
                                      return AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text('Unlock This Category', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('To unlock this category, please share the app on at least two of the following social platforms:', style: GoogleFonts.poppins()),
                                            SizedBox(height: 16),
                                            Wrap(
                                              spacing: 12,
                                              children: [
                                                _buildShareButton(context, 'Facebook', 'facebook', sharedPlatforms, setState, userProvider, user),
                                                _buildShareButton(context, 'X', 'twitter', sharedPlatforms, setState, userProvider, user),
                                                _buildShareButton(context, 'TikTok', 'tiktok', sharedPlatforms, setState, userProvider, user),
                                                _buildShareButton(context, 'Instagram', 'instagram', sharedPlatforms, setState, userProvider, user),
                                                _buildCopyLinkButton(context, sharedPlatforms, setState, userProvider, user),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            Text('Progress: $sharedCount/2 platforms shared', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: sharedCount >= 2
                                                ? () {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Category unlocked!')),
                                                    );
                                                  }
                                                : null,
                                            child: Text('Unlock Category', style: GoogleFonts.poppins(color: sharedCount >= 2 ? Colors.indigo : Colors.grey, fontWeight: FontWeight.bold)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          : null,
                  child: Card(
                    color: isUnlocked ? Colors.white : Colors.grey[200],
                    elevation: isUnlocked ? 5 : 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            categoryIcons[categories[index]['name']?.toLowerCase() ?? ''] ?? Icons.category,
                            color: isUnlocked ? Colors.indigo : Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 16),
                          Text(
                            categories[index]['name'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          isUnlocked
                              ? Icon(Icons.lock_open, color: Colors.green)
                              : Icon(Icons.lock, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCopyLinkButton(BuildContext context, Map<String, bool> sharedPlatforms, void Function(void Function()) setState, UserProvider userProvider, user) {
    bool isShared = sharedPlatforms['copy'] == true;
    return ElevatedButton.icon(
      onPressed: isShared
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: 'https://your-app-link.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link copied to clipboard!')),
              );
              final newPlatforms = Map<String, bool>.from(sharedPlatforms);
              newPlatforms['copy'] = true;
              userProvider.updateSharedPlatforms(newPlatforms);
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'sharedPlatforms': newPlatforms});
              setState(() {});
            },
      icon: Icon(Icons.copy, color: isShared ? Colors.green : Colors.indigo),
      label: Text('Copy Link', style: GoogleFonts.poppins(color: isShared ? Colors.green : Colors.indigo)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isShared ? Colors.green[50] : Colors.white,
        foregroundColor: isShared ? Colors.green : Colors.indigo,
        side: BorderSide(color: isShared ? Colors.green : Colors.indigo),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, String label, String platform, Map<String, bool> sharedPlatforms, void Function(void Function()) setState, UserProvider userProvider, user) {
    bool isShared = sharedPlatforms[platform] == true;
    return ElevatedButton.icon(
      onPressed: isShared
          ? null
          : () async {
              final appLink = 'https://your-app-link.com';
              if (platform == 'facebook') {
                final url = 'https://www.facebook.com/sharer/sharer.php?u=$appLink';
                await Share.share('Check out this app! $appLink', subject: 'Exam App', sharePositionOrigin: Rect.zero);
              } else if (platform == 'twitter') {
                final url = 'https://twitter.com/intent/tweet?url=$appLink&text=Check+out+this+app!';
                await Share.share('Check out this app! $appLink', subject: 'Exam App', sharePositionOrigin: Rect.zero);
              } else {
                await Share.share('Check out this awesome Multiple Choice Exam App! $appLink');
              }
              // Mark as shared
              final newPlatforms = Map<String, bool>.from(sharedPlatforms);
              newPlatforms[platform] = true;
              userProvider.updateSharedPlatforms(newPlatforms);
              // Update Firestore
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'sharedPlatforms': newPlatforms});
              setState(() {});
            },
      icon: Icon(_getPlatformIcon(platform), color: isShared ? Colors.green : Colors.indigo),
      label: Text(label, style: GoogleFonts.poppins(color: isShared ? Colors.green : Colors.indigo)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isShared ? Colors.green[50] : Colors.white,
        foregroundColor: isShared ? Colors.green : Colors.indigo,
        side: BorderSide(color: isShared ? Colors.green : Colors.indigo),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_note;
      case 'instagram':
        return Icons.camera_alt;
      default:
        return Icons.share;
    }
  }
} 