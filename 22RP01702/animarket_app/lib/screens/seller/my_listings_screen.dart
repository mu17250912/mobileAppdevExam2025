import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/animal.dart';
import '../../screens/seller/animal_detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('My Listings', style: TextStyle(color: Colors.white)),
      ),
      body: user == null
          ? Center(child: Text('Not logged in'))
          : StreamBuilder<List<Animal>>(
              stream: Provider.of<AnimalProvider>(context, listen: false).getSellerAnimalsStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                // Enhanced debugging
                print('Current user ID: ${user.id}');
                print('User ID type: ${user.id.runtimeType}');
                
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading listings: ${snapshot.error}',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  print('Fetched ${snapshot.data!.length} animals for userId: \'${user.id}\'');
                  for (var animal in snapshot.data!) {
                    print('Animal: userId=${animal.userId} (type: ${animal.userId.runtimeType}), type=${animal.type}, price=${animal.price}, location=${animal.location}');
                  }
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add Your First Animal',
                          style: TextStyle(fontSize: 20, color: kGrayText),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'User ID: ${user.id}',
                          style: TextStyle(fontSize: 12, color: kGrayText),
                        ),
                      ],
                    ),
                  );
                }
                
                final listings = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final item = listings[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Text(_getEmoji(item.type), style: TextStyle(fontSize: 36)),
                        title: Text('${item.type} - RWF ${item.price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: kPrimaryGreen),
                                SizedBox(width: 4),
                                Text(item.location, style: TextStyle(color: kGrayText)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(item.description, style: TextStyle(color: kGrayText)),
                            Text('Count: ${item.count}'),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AnimalDetailScreen(animal: item, isSeller: true),
                          ));
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AnimalDetailScreen(animal: item, isSeller: true),
                              ));
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Delete Animal'),
                                  content: Text('Are you sure you want to delete this animal?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete')),
                                  ],
                                ),
                              ).then((confirmed) {
                                if (confirmed == true) {
                                  Provider.of<AnimalProvider>(context, listen: false).removeAnimal(item.id);
                                }
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'view', child: Text('View')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
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
