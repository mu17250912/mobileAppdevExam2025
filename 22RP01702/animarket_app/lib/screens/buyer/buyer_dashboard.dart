import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/animal.dart';
import 'animal_detail_screen.dart';
import 'profile_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';

class BuyerDashboard extends StatefulWidget {
  @override
  _BuyerDashboardState createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final buyerLocation = user?.location ?? '';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: Text('Hello, Buyer!', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Animal>>(
              stream: Provider.of<AnimalProvider>(context, listen: false).getAllAnimalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No animals found.',
                      style: TextStyle(fontSize: 20, color: kGrayText),
                    ),
                  );
                }
                var animals = snapshot.data!;

                // Filter by search query
                if (searchQuery.isNotEmpty) {
                  animals = animals.where((a) => a.location.toLowerCase().contains(searchQuery)).toList();
                }

                // Sort: animals in buyer's location first
                animals.sort((a, b) {
                  if (a.isPremium && !b.isPremium) return -1;
                  if (!a.isPremium && b.isPremium) return 1;
                  // Then sort by location as before
                  if (a.location == buyerLocation && b.location != buyerLocation) return -1;
                  if (a.location != buyerLocation && b.location == buyerLocation) return 1;
                  return 0;
                });

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Text(_getEmoji(animal.type), style: TextStyle(fontSize: 36)),
                        title: Row(
                          children: [
                            Text('${animal.type} - RWF ${animal.price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (animal.isPremium)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Premium', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: kPrimaryGreen),
                                SizedBox(width: 4),
                                Text(animal.location, style: TextStyle(color: kGrayText)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(animal.description, style: TextStyle(color: kGrayText)),
                            SizedBox(height: 4),
                            Text('Count: ${animal.count}', style: TextStyle(color: kGrayText)),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AnimalDetailScreen(animal: animal, isSeller: false), // isSeller: false for buyers
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
