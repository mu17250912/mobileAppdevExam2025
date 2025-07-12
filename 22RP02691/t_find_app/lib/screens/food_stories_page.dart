import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodStoriesPage extends StatefulWidget {
  const FoodStoriesPage({Key? key}) : super(key: key);

  @override
  State<FoodStoriesPage> createState() => _FoodStoriesPageState();
}

class _FoodStoriesPageState extends State<FoodStoriesPage> {
  void _showStoryDetails(Map<String, dynamic> story) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final maxDialogWidth = screenSize.width < 700 ? screenSize.width * 0.95 : 600.0;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: screenSize.height * 0.9,
              ),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C7B7B),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              story['title'] ?? 'Story Details',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            if (story['productImage'] != null && story['productImage'].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 16 / 7,
                                  child: Image.asset(
                                    story['productImage'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Vendor Email
                            if (story['vendorEmail'] != null && story['vendorEmail'].toString().isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.person, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      story['vendorEmail'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            // Description
                            if (story['description'] != null && story['description'].toString().isNotEmpty) ...[
                              const Text(
                                'Description:',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                story['description'],
                                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Product Name
                            if (story['productName'] != null && story['productName'].toString().isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.fastfood, size: 18, color: Colors.orange[400]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      story['productName'],
                                      style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            // Timestamp
                            if (story['timestamp'] != null && story['timestamp'] is Timestamp)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Posted: ${(story['timestamp'] as Timestamp).toDate().toLocal()}',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9C7B7B),
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
      },
    );
  }

  void _showAllStories(List<Map<String, dynamic>> stories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF9C7B7B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All Food Stories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return ListTile(
                    leading: story['productImage'] != null && story['productImage'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              story['productImage'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, size: 30, color: Colors.grey),
                                );
                              },
                            ),
                          )
                        : const Icon(Icons.image, size: 40, color: Colors.grey),
                    title: Text(
                      story['title'] ?? '', 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (story['productName'] != null)
                          Text(
                            story['productName'], 
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (story['description'] != null)
                          Text(
                            story['description'].toString().length > 50
                                ? story['description'].toString().substring(0, 50) + '...'
                                : story['description'],
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      try {
                        _showStoryDetails(story);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading story details: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFF9C7B7B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Food Stories', style: TextStyle(color: Colors.black)),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No stories found.'));
          }
          
          final stories = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data;
          }).toList().cast<Map<String, dynamic>>();

          if (stories.isEmpty) {
            return const Center(child: Text('No stories found.'));
          }

          final featured = stories[0];
          final moreStories = stories.length > 1 ? stories.sublist(1).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

          // Responsive layout for tablet/desktop
          if (isTablet) {
            return _buildTabletLayout(screenSize, featured, moreStories, stories);
          }

          // Mobile layout
          return _buildMobileLayout(screenSize, featured, moreStories, stories);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Size screenSize, Map<String, dynamic> featured, List<Map<String, dynamic>> moreStories, List<Map<String, dynamic>> stories) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenSize.width * 0.04), // 4% of screen width
      child: Column(
        children: [
          // Logo and Title
          Image.asset(
            'assets/images/logo1.png',
            width: screenSize.width * 0.25, // 25% of screen width
            height: screenSize.width * 0.25,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: screenSize.width * 0.25,
                height: screenSize.width * 0.25,
                color: Colors.grey[200],
                child: Icon(Icons.image, size: screenSize.width * 0.125, color: Colors.grey),
              );
            },
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            'T-Find',
            style: TextStyle(
              fontSize: screenSize.width * 0.09, // 9% of screen width
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF8800),
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
          
          // Featured Story
          GestureDetector(
            onTap: () {
              try {
                _showStoryDetails(featured);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading story details: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Featured Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.08),
                  child: (featured['productImage'] != null && featured['productImage'].toString().isNotEmpty)
                    ? Image.asset(
                        featured['productImage'],
                        width: double.infinity,
                        height: screenSize.height * 0.25, // 25% of screen height
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: screenSize.height * 0.25,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: screenSize.width * 0.16, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: screenSize.height * 0.25,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: screenSize.width * 0.16, color: Colors.grey),
                      ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                
                // Featured Story Content
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.04),
                  ),
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              featured['title'] ?? '',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (featured['productName'] != null && featured['productName'].toString().isNotEmpty) ...[
                            Icon(Icons.fastfood, color: Colors.orange[400], size: screenSize.width * 0.05),
                            SizedBox(width: screenSize.width * 0.01),
                            Flexible(
                              child: Text(
                                featured['productName'], 
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenSize.width * 0.035,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: screenSize.height * 0.01),
                      if (featured['description'] != null && featured['description'].toString().isNotEmpty)
                        Text(
                          featured['description'].toString().length > 100
                              ? featured['description'].toString().substring(0, 100) + '...'
                              : featured['description'],
                          style: TextStyle(
                            color: Colors.black, 
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      SizedBox(height: screenSize.height * 0.01),
                      Row(
                        children: [
                          if (featured['vendorEmail'] != null && featured['vendorEmail'].toString().isNotEmpty)
                            Expanded(
                              child: Text(
                                'By ${featured['vendorEmail']}',
                                style: TextStyle(
                                  color: Colors.grey[700], 
                                  fontSize: screenSize.width * 0.03,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (featured['timestamp'] != null && featured['timestamp'] is Timestamp)
                            Flexible(
                              child: Text(
                                '${(featured['timestamp'] as Timestamp).toDate().toLocal()}',
                                style: TextStyle(
                                  color: Colors.grey[700], 
                                  fontSize: screenSize.width * 0.03,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
          
          // View All Stories Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAllStories(stories),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: Size.fromHeight(screenSize.height * 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.06),
                ),
              ),
              child: Text(
                'View All Stories',
                style: TextStyle(
                  fontSize: screenSize.width * 0.045,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
          
          // More Stories
          if (moreStories.isNotEmpty) ...[
            Text(
              'More Stories',
              style: TextStyle(
                fontSize: screenSize.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            ...moreStories.map((story) => Padding(
              padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
              child: GestureDetector(
                onTap: () {
                  try {
                    _showStoryDetails(story);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error loading story details: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(screenSize.width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.03),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(screenSize.width * 0.02),
                        child: (story['productImage'] != null && story['productImage'].toString().isNotEmpty)
                          ? Image.asset(
                              story['productImage'],
                              width: screenSize.width * 0.12,
                              height: screenSize.width * 0.12,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: screenSize.width * 0.12,
                                  height: screenSize.width * 0.12,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, color: Colors.grey, size: screenSize.width * 0.06),
                                );
                              },
                            )
                          : Container(
                              width: screenSize.width * 0.12,
                              height: screenSize.width * 0.12,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey, size: screenSize.width * 0.06),
                            ),
                      ),
                      SizedBox(width: screenSize.width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: screenSize.width * 0.04,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (story['productName'] != null && story['productName'].toString().isNotEmpty)
                              Text(
                                story['productName'],
                                style: TextStyle(
                                  color: Colors.grey[300], 
                                  fontSize: screenSize.width * 0.03,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: screenSize.width * 0.04),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout(Size screenSize, Map<String, dynamic> featured, List<Map<String, dynamic>> moreStories, List<Map<String, dynamic>> stories) {
    final maxCardWidth = 900.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenSize.width * 0.02),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo1.png',
                    width: screenSize.width * 0.08,
                    height: screenSize.width * 0.08,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: screenSize.width * 0.08,
                        height: screenSize.width * 0.08,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: screenSize.width * 0.04, color: Colors.grey),
                      );
                    },
                  ),
                  SizedBox(width: screenSize.width * 0.02),
                  Text(
                    'T-Find',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF8800),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _showAllStories(stories),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.02,
                        vertical: screenSize.height * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenSize.width * 0.01),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'View All Stories',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.015,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.03),
              
              // Featured Story Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (featured['productImage'] != null && featured['productImage'].toString().isNotEmpty)
                          ? Image.asset(
                              featured['productImage'],
                              width: 260,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 260,
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                                );
                              },
                            )
                          : Container(
                              width: 260,
                              height: 180,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 64, color: Colors.grey),
                            ),
                      ),
                      SizedBox(width: 32),
                      // Featured Story Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              featured['title'] ?? '',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            SizedBox(height: 12),
                            if (featured['description'] != null && featured['description'].toString().isNotEmpty)
                              Text(
                                featured['description'].toString().length > 200
                                    ? featured['description'].toString().substring(0, 200) + '...'
                                    : featured['description'],
                                style: TextStyle(
                                  color: Colors.black87, 
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 5,
                              ),
                            SizedBox(height: 16),
                            if (featured['productName'] != null && featured['productName'].toString().isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.fastfood, color: Colors.orange[400], size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    featured['productName'],
                                    style: TextStyle(
                                      color: Colors.orange[400],
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            SizedBox(height: 8),
                            if (featured['vendorEmail'] != null && featured['vendorEmail'].toString().isNotEmpty)
                              Text(
                                'By ${featured['vendorEmail']}',
                                style: TextStyle(
                                  color: Colors.grey[700], 
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.04),
              
              // More Stories Section
              Text(
                'More Stories',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenSize.width > 900 ? 3 : 2,
                  childAspectRatio: 1.7,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: moreStories.length,
                itemBuilder: (context, index) {
                  final story = moreStories[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        try {
                          _showStoryDetails(story);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error loading story details: \\${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (story['productImage'] != null && story['productImage'].toString().isNotEmpty)
                                ? Image.asset(
                                    story['productImage'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.image, color: Colors.grey, size: 32),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image, color: Colors.grey, size: 32),
                                  ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    story['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (story['productName'] != null && story['productName'].toString().isNotEmpty)
                                    Text(
                                      story['productName'],
                                      style: TextStyle(
                                        color: Colors.orange[400],
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  if (story['vendorEmail'] != null && story['vendorEmail'].toString().isNotEmpty)
                                    Text(
                                      'By ${story['vendorEmail']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 