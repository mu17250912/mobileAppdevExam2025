import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'buses_screen.dart';
import 'seat_selection_screen.dart'; // Added import for SeatSelectionScreen

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(child: Text('Please log in to view your favorites.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ListView(
        children: [
          // Favorite Routes Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Favorite Routes', style: Theme.of(context).textTheme.titleLarge),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('favorites')
                .where('userId', isEqualTo: user.uid)
                .where('routeId', isGreaterThan: '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('You have no favorite routes yet.', style: TextStyle(fontSize: 18)));
              }
              final favoriteDocs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favoriteDocs.length,
                itemBuilder: (context, index) {
                  final fav = favoriteDocs[index];
                  final routeId = fav['routeId'];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('routes').doc(routeId).get(),
                    builder: (context, routeSnap) {
                      if (!routeSnap.hasData) {
                        return const ListTile(title: Text('Loading route...'));
                      }
                      final route = routeSnap.data!;
                      final data = route.data() as Map<String, dynamic>?;
                      if (data == null) {
                        return const ListTile(title: Text('Route not found'));
                      }
                      return Dismissible(
                        key: ValueKey(fav.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await fav.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Removed from favorites.')),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text('${data['from']} → ${data['to']}'),
                          subtitle: Text('Distance: ${data['distanceKm']} km, Duration: ${data['estimatedDuration']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await fav.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Removed from favorites.')),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BusesScreen(
                                  routeId: route.id,
                                  routeName: '${data['from']} → ${data['to']}',
                                ),
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
          // Favorite Buses Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Favorite Buses', style: Theme.of(context).textTheme.titleLarge),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('favorites')
                .where('userId', isEqualTo: user.uid)
                .where('busId', isGreaterThan: '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('You have no favorite buses yet.', style: TextStyle(fontSize: 18)));
              }
              final favoriteDocs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favoriteDocs.length,
                itemBuilder: (context, index) {
                  final fav = favoriteDocs[index];
                  final busId = fav['busId'];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('buses').doc(busId).get(),
                    builder: (context, busSnap) {
                      if (!busSnap.hasData) {
                        return const ListTile(title: Text('Loading bus...'));
                      }
                      final bus = busSnap.data!;
                      final data = bus.data() as Map<String, dynamic>?;
                      if (data == null) {
                        return const ListTile(title: Text('Bus not found'));
                      }
                      return Dismissible(
                        key: ValueKey(fav.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await fav.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Removed from favorites.')),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus, color: Colors.blue),
                          title: Text('${data['company']} - ${data['plateNumber']}'),
                          subtitle: Text('Departure: ${data['departureTime']} | Seats: ${data['availableSeats']}/${data['totalSeats']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await fav.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Removed from favorites.')),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SeatSelectionScreen(
                                  busId: bus.id,
                                  busData: data,
                                ),
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
        ],
      ),
    );
  }
} 