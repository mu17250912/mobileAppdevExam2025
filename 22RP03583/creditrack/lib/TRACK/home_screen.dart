import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Do nothing if already on the selected tab
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home: pop to root or do nothing
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/loan');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/contacts');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/messages');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  final List<_FeatureCardData> features = [
    _FeatureCardData(Icons.account_balance_wallet, "Loans", "Manage portfolio", '/loan'),
    _FeatureCardData(Icons.people, "Borrowers", "Verify & track", '/add_borrower'),
    _FeatureCardData(Icons.payment, "Payments", "Track & remind", '/payments'),
    _FeatureCardData(Icons.analytics, "Analytics", "View reports", '/analytics'),
    _FeatureCardData(Icons.description, "Contracts", "Digital signing", '/contracts'),
    _FeatureCardData(Icons.notifications, "Notifications", "View alerts", '/notifications'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7B8AFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF7B8AFF),
        elevation: 0,
        title: Text('CrediTrack', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            if (features[index].route == '/add_borrower') {
              return _borrowersCountCard(features[index]);
            }
            final feature = features[index];
            return _featureCard(feature);
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.pushNamed(context, '/add_borrower');
            },
            child: Container(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: Color(0xFF7B8AFF), size: 32),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').where('read', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData) {
            unreadCount = snapshot.data!.docs.length;
          }
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Color(0xFF7B8AFF),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Loans'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.message),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Messages',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            type: BottomNavigationBarType.fixed,
          );
        },
      ),
    );
  }

  Widget _featureCard(_FeatureCardData data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (data.route != null) {
            Navigator.pushNamed(context, data.route!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      data.title == 'Contracts'
                          ? Color(0xFF7B5CFA)
                          : Color(0xFF7B8AFF),
                      data.title == 'Contracts'
                          ? Color(0xFF6A82FB)
                          : Color(0xFFB2B8FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 36,
                  ),
                  radius: 32,
                ),
              ),
              SizedBox(height: 18),
              Text(
                data.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _borrowersCountCard(_FeatureCardData data) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('borrowers').get(),
      builder: (context, snapshot) {
        String subtitle = 'Loading...';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final count = snapshot.data!.docs.length;
          subtitle = '$count borrowers';
        } else if (snapshot.hasError) {
          subtitle = 'Error';
        }
        return _featureCard(_FeatureCardData(data.icon, data.title, subtitle, data.route));
      },
    );
  }
}

class _FeatureCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  const _FeatureCardData(this.icon, this.title, this.subtitle, [this.route]);
} 