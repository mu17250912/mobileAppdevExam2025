import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'buses_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Routes'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No routes available.'));
          }
          final routes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final routeId = route.id;
              final data = route.data() as Map<String, dynamic>;
              return FutureBuilder<QuerySnapshot>(
                future: user == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('favorites')
                        .where('userId', isEqualTo: user.uid)
                        .where('routeId', isEqualTo: routeId)
                        .get(),
                builder: (context, favSnapshot) {
                  final isFavorite = favSnapshot.hasData && favSnapshot.data!.docs.isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFF5F6FA),
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus, color: Color(0xFF003366)),
                      title: Text('${data['from']} → ${data['to']}', style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                      subtitle: Text('Distance: ${data['distanceKm']} km, Duration: ${data['estimatedDuration']}', style: const TextStyle(color: Color(0xFF003366))),
                      trailing: user == null
                          ? null
                          : IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                              onPressed: () async {
                                final favRef = FirebaseFirestore.instance.collection('favorites');
                                if (isFavorite) {
                                  // Remove favorite
                                  final favDoc = favSnapshot.data!.docs.first;
                                  await favDoc.reference.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Removed from favorites.')),
                                  );
                                } else {
                                  // Add favorite
                                  await favRef.add({
                                    'userId': user.uid,
                                    'routeId': routeId,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Added to favorites!')),
                                  );
                                }
                              },
                            ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusesScreen(routeId: routeId, routeName: '${data['from']} → ${data['to']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 