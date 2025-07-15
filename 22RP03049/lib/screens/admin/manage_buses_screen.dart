import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBusesScreen extends StatelessWidget {
  const ManageBusesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Buses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No buses found.'));
          }
          final buses = snapshot.data!.docs;
          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text(bus['plateNumber'] ?? ''),
                  subtitle: Text('Company: ${bus['company'] ?? ''}\nRoute: ${bus['routeId'] ?? ''}\nDeparture: ${bus['departureTime'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showBusDialog(context, bus: bus),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, bus.id),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Bus',
      ),
    );
  }

  void _showBusDialog(BuildContext context, {DocumentSnapshot? bus}) async {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: bus?['plateNumber'] ?? '');
    final companyController = TextEditingController(text: bus?['company'] ?? '');
    final departureController = TextEditingController(text: bus?['departureTime'] ?? '');
    final totalSeatsController = TextEditingController(text: bus?['totalSeats']?.toString() ?? '');
    String? selectedRouteId = bus?['routeId'];
    List<QueryDocumentSnapshot> routes = [];
    // Fetch routes for dropdown
    try {
      final routesSnap = await FirebaseFirestore.instance.collection('routes').get();
      routes = routesSnap.docs;
    } catch (_) {}
    // Fix: Ensure selectedRouteId is valid
    if (routes.isNotEmpty && (selectedRouteId == null || !routes.any((route) => route.id == selectedRouteId))) {
      selectedRouteId = routes.first.id;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bus == null ? 'Add Bus' : 'Edit Bus'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'Plate Number'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedRouteId,
                  items: routes.map((route) {
                    return DropdownMenuItem<String>(
                      value: route.id,
                      child: Text('${route['from']} → ${route['to']}'),
                    );
                  }).toList(),
                  onChanged: (val) => selectedRouteId = val,
                  decoration: const InputDecoration(labelText: 'Route'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: departureController,
                  decoration: const InputDecoration(labelText: 'Departure Time (ISO)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: totalSeatsController,
                  decoration: const InputDecoration(labelText: 'Total Seats'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = {
                  'plateNumber': plateController.text.trim(),
                  'company': companyController.text.trim(),
                  'routeId': selectedRouteId,
                  'departureTime': departureController.text.trim(),
                  'totalSeats': int.tryParse(totalSeatsController.text.trim()) ?? 0,
                  'availableSeats': int.tryParse(totalSeatsController.text.trim()) ?? 0,
                };
                try {
                  if (bus == null) {
                    final int totalSeats = int.tryParse(totalSeatsController.text.trim()) ?? 0;
                    final seats = List.generate(
                      totalSeats,
                      (index) => {
                        'seatNumber': index + 1,
                        'booked': false,
                      },
                    );
                    data['seats'] = seats;
                    await FirebaseFirestore.instance.collection('buses').add(data);
                  } else {
                    await FirebaseFirestore.instance.collection('buses').doc(bus.id).update(data);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(bus == null ? 'Bus added' : 'Bus updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(bus == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String busId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: const Text('Are you sure you want to delete this bus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('buses').doc(busId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bus deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 