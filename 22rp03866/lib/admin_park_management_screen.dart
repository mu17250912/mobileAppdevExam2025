import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'theme/colors.dart';

class AdminParkManagementScreen extends StatefulWidget {
  const AdminParkManagementScreen({super.key});

  @override
  State<AdminParkManagementScreen> createState() => _AdminParkManagementScreenState();
}

class _AdminParkManagementScreenState extends State<AdminParkManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  LatLng? _pickedLatLng;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdatePark({String? docId}) async {
    if (_formKey.currentState!.validate()) {
      final parkData = <String, dynamic>{};
      parkData['name'] = _nameController.text.trim();
      parkData['description'] = _descriptionController.text.trim();
      parkData['image'] = _imageController.text.trim();
      parkData['location'] = _locationController.text.trim();
      parkData['price'] = _priceController.text.trim();
      if (_pickedLatLng != null) {
        parkData['latitude'] = _pickedLatLng!.latitude;
        parkData['longitude'] = _pickedLatLng!.longitude;
      }
      try {
        if (docId == null) {
          await FirebaseFirestore.instance.collection('parks').add(parkData);
        } else {
          await FirebaseFirestore.instance.collection('parks').doc(docId).update(parkData);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(docId == null ? 'Park added!' : 'Park updated!')),
        );
        _nameController.clear();
        _descriptionController.clear();
        _imageController.clear();
        _locationController.clear();
        _priceController.clear();
        _pickedLatLng = null; // Clear picked location after saving
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _populateFields(Map<String, dynamic> park) {
    _nameController.text = park['name'] ?? '';
    _descriptionController.text = park['description'] ?? '';
    _imageController.text = park['image'] ?? '';
    _locationController.text = park['location'] ?? '';
    _priceController.text = park['price'] ?? '';
    if (park['latitude'] != null && park['longitude'] != null) {
      _pickedLatLng = LatLng(park['latitude'], park['longitude']);
    }
  }

  void _showAddParkDialog(BuildContext context) {
    _nameController.clear();
    _descriptionController.clear();
    _imageController.clear();
    _locationController.clear();
    _priceController.clear();
    _pickedLatLng = null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Park', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Park Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.park, color: AppColors.primary),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter park name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.description, color: AppColors.primary),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Enter description' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: InputDecoration(
                    labelText: 'Image Asset Path',
                    hintText: 'e.g., assets/serengeti.png',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.image, color: AppColors.primary),
                    helperText: 'Available: serengeti.png, kruger.png, JimCorbett.png, volcanoes.png, Zhangjiajie.png, fiordland.png, grandcanyon.png, masai.png',
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price ( 24)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter price' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _addOrUpdatePark();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Add Park', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Park Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
            onPressed: () => _showAddParkDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.data_array, color: theme.colorScheme.onPrimary),
            onPressed: () => _populateSampleParks(),
            tooltip: 'Add Sample Parks',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Parks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add, edit, or remove parks from your SafariGo app',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('parks').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.park, size: 80, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                          SizedBox(height: 16),
                          Text(
                            'No parks found!',
                            style: TextStyle(fontSize: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                          ),
                          Text(
                            'Add your first park to get started.',
                            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    );
                  }
                  final parks = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: parks.length,
                    itemBuilder: (context, index) {
                      final park = parks[index].data() as Map<String, dynamic>;
                      final docId = parks[index].id;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: park['image'] != null && park['image'].toString().isNotEmpty
                                    ? Image.asset(
                                        park['image'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: AppColors.lightGrey,
                                            child: Icon(Icons.image_not_supported, color: AppColors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: AppColors.lightGrey,
                                        child: Icon(Icons.image_not_supported, color: AppColors.grey),
                                      ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      park['name'] ?? 'Unknown Park',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      park['description'] ?? 'No description',
                                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Location: ${park['location'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Price: \$${park['price'] ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditParkDialog(context, docId, park);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context, docId, park['name']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: AppColors.info),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: AppColors.danger),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  void _showEditParkDialog(BuildContext context, String docId, Map<String, dynamic> park) {
    _populateFields(park);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Park', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Park Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.park, color: AppColors.primary),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter park name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.description, color: AppColors.primary),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Enter description' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: InputDecoration(
                    labelText: 'Image Asset Path',
                    hintText: 'e.g., assets/serengeti.png',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.image, color: AppColors.primary),
                    helperText: 'Available: serengeti.png, kruger.png, JimCorbett.png, volcanoes.png, Zhangjiajie.png, fiordland.png, grandcanyon.png, masai.png',
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price ( 24)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter price' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _addOrUpdatePark(docId: docId);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Update Park', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _populateSampleParks() async {
    final sampleParks = [
      {
        'name': 'Kruger National Park',
        'description': 'One of Africa\'s largest game reserves, home to the Big Five and diverse wildlife.',
        'image': 'assets/kruger.png',
        'location': 'South Africa',
        'price': '150',
      },
      {
        'name': 'Jim Corbett National Park',
        'description': 'India\'s oldest national park, famous for Bengal tigers and rich biodiversity.',
        'image': 'assets/JimCorbett.png',
        'location': 'India',
        'price': '120',
      },
      {
        'name': 'Volcanoes National Park',
        'description': 'Home to endangered mountain gorillas and stunning volcanic landscapes.',
        'image': 'assets/volcanoes.png',
        'location': 'Rwanda',
        'price': '200',
      },
      {
        'name': 'Zhangjiajie National Forest Park',
        'description': 'Inspiration for Avatar\'s floating mountains, featuring unique sandstone pillars.',
        'image': 'assets/Zhangjiajie.png',
        'location': 'China',
        'price': '180',
      },
      {
        'name': 'Fiordland National Park',
        'description': 'New Zealand\'s largest national park with stunning fjords and waterfalls.',
        'image': 'assets/fiordland.png',
        'location': 'New Zealand',
        'price': '160',
      },
      {
        'name': 'Grand Canyon National Park',
        'description': 'Iconic natural wonder with breathtaking views and geological history.',
        'image': 'assets/grandcanyon.png',
        'location': 'USA',
        'price': '140',
      },
      {
        'name': 'Masai Mara Reserve',
        'description': 'Famous for the Great Migration and abundant wildlife in Kenya.',
        'image': 'assets/masai.png',
        'location': 'Kenya',
        'price': '170',
      },
      {
        'name': 'Serengeti National Park',
        'description': 'Tanzania\'s premier wildlife destination with vast savannahs and wildlife.',
        'image': 'assets/serengeti.png',
        'location': 'Tanzania',
        'price': '190',
      },
    ];

    try {
      for (final park in sampleParks) {
        await FirebaseFirestore.instance.collection('parks').add(park);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sample parks added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding sample parks: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String docId, String? parkName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Park', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$parkName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('parks').doc(docId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Park "$parkName" deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete park: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 