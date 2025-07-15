import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'add_animal_screen.dart';
import 'my_listings_screen.dart';
import '../buyer/notifications_screen.dart';
import 'profile_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/animal.dart';
import '../common/paypal_webview_screen.dart';

class SellerDashboard extends StatefulWidget {
  final int initialTabIndex;
  SellerDashboard({this.initialTabIndex = 0});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  final List<Widget> _screens = [
    SellerHomeScreen(),
    AddAnimalScreen(),
    MyListingsScreen(),
    NotificationsScreen(),
    SellerProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        isSeller: true,
      ),
    );
  }
}

class SellerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: Text('Welcome, Seller!', style: TextStyle(color: Colors.white)),
      ),
      body: user == null
          ? Center(child: Text('Not logged in'))
          : StreamBuilder<List<Animal>>(
              stream: Provider.of<AnimalProvider>(context, listen: false).getSellerAnimalsStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No listings yet.'));
                }
                final animals = snapshot.data ?? [];
                final totalValue = animals.fold<double>(0, (sum, a) => sum + a.price);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          _buildStatCard('Active Listings', animals.length.toString()),
                          SizedBox(width: 16),
                          _buildStatCard('Total Value', 'RWF ${totalValue.toStringAsFixed(0)}'),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AddAnimalScreen()),
                                );
                              },
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text('Add Animal', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => MyListingsScreen()),
                                );
                              },
                              icon: Icon(Icons.list, color: kPrimaryGreen),
                              label: Text('My Listings', style: TextStyle(color: kPrimaryGreen)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryGreen,
                                side: BorderSide(color: kPrimaryGreen),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Recent listings preview
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Recent Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkText)),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: animals.isEmpty
                            ? Center(child: Text('No listings yet.'))
                            : ListView(
                                children: animals.take(3).map((animal) => _buildListingPreview(
                                  _getEmoji(animal.type),
                                  animal.type,
                                  animal.price,
                                  animal.location,
                                )).toList(),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        color: kLightGreen.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              SizedBox(height: 8),
              Text(title, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingPreview(String emoji, String type, double price, String location) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(emoji, style: TextStyle(fontSize: 36)),
        title: Text('$type - RWF ${price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(Icons.location_on, size: 16, color: kPrimaryGreen),
            SizedBox(width: 4),
            Text(location, style: TextStyle(color: kGrayText)),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: kPrimaryGreen),
        onTap: () {
          // TODO: View listing details
        },
      ),
    );
  }

  String _getEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'cow':
        return '🐄';
      case 'goat':
        return '🐐';
      case 'chicken':
        return '🐔';
      case 'pig':
        return '🐖';
      default:
        return '🐾';
    }
  }
}
