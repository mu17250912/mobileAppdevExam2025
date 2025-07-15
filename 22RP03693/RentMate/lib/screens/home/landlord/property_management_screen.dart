import 'package:flutter/material.dart';
import '../../../models/property.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../providers/property_provider.dart';
import 'add_property_screen.dart';
import '../../../providers/auth_provider.dart';

class PropertyManagementScreen extends StatelessWidget {
  const PropertyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    return FutureBuilder<List<Property>>(
      future: user != null ? propertyProvider.getPropertiesByLandlord(user.id) : Future.value([]),
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Properties'),
          ),
          body: properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_work_outlined, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 24),
                      const Text('No properties found.', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Click the + button to add your first property!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Clicked on ${property.title}')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: property.images.isNotEmpty
                              ? Image.network(property.images.first, width: 60, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.home, size: 40),
                          title: Text(property.title),
                          subtitle: Text(property.address),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AddPropertyScreen(property: property),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  propertyProvider.removeProperty(property.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted ${property.title}')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
} 