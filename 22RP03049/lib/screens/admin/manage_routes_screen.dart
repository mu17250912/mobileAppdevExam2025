import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRoutesScreen extends StatelessWidget {
  const ManageRoutesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No routes found.'));
          }
          final routes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: Text('${route['from']} → ${route['to']}'),
                  subtitle: Text('Distance: ${route['distanceKm']} km, Duration: ${route['estimatedDuration']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRouteDialog(context, route: route),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, route.id),
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
        onPressed: () => _showRouteDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Route',
      ),
    );
  }

  void _showRouteDialog(BuildContext context, {DocumentSnapshot? route}) {
    final formKey = GlobalKey<FormState>();
    final fromController = TextEditingController(text: route?['from'] ?? '');
    final toController = TextEditingController(text: route?['to'] ?? '');
    final distanceController = TextEditingController(text: route?['distanceKm']?.toString() ?? '');
    final durationController = TextEditingController(text: route?['estimatedDuration'] ?? '');
    bool isActive = route?['active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route == null ? 'Add Route' : 'Edit Route'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fromController,
                  decoration: const InputDecoration(labelText: 'From'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: toController,
                  decoration: const InputDecoration(labelText: 'To'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: distanceController,
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Estimated Duration'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                SwitchListTile(
                  value: isActive,
                  onChanged: (val) {
                    isActive = val;
                  },
                  title: const Text('Active'),
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
                  'from': fromController.text.trim(),
                  'to': toController.text.trim(),
                  'distanceKm': int.tryParse(distanceController.text.trim()) ?? 0,
                  'estimatedDuration': durationController.text.trim(),
                  'active': isActive,
                };
                try {
                  if (route == null) {
                    await FirebaseFirestore.instance.collection('routes').add(data);
                  } else {
                    await FirebaseFirestore.instance.collection('routes').doc(route.id).update(data);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(route == null ? 'Route added' : 'Route updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(route == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String routeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('routes').doc(routeId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route deleted')),
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