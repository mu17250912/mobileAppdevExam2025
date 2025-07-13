import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/available_cars_screen.dart';
import 'screens/car_details_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'screens/notifications_screen.dart';
import 'screens/booking_cancellation_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/premium_unlock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/admin_premium_screen.dart';

// Placeholder screens for Admin panels
class AdminManageCarsScreen extends StatefulWidget {
  @override
  _AdminManageCarsScreenState createState() => _AdminManageCarsScreenState();
}

class _AdminManageCarsScreenState extends State<AdminManageCarsScreen> {
  List<String> _assetImages = [];

  @override
  void initState() {
    super.initState();
    _loadAssetImages();
  }

  Future<void> _loadAssetImages() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final images = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/images/') &&
            (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')) &&
            !key.endsWith('logo.png')) // Exclude logo.png
        .toList();
    setState(() {
      _assetImages = images;
    });
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      if (kIsWeb) {
        // Web: use file_picker
        final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
        if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
          print('No file picked or file is empty');
          return null;
        }
        final file = result.files.first;
        final fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        try {
          final snapshot = await ref.putData(file.bytes!).timeout(Duration(seconds: 30));
          if (context.mounted) {
          Navigator.pop(context);
          }
          return await snapshot.ref.getDownloadURL();
        } on TimeoutException {
          if (context.mounted) {
          Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload timed out. Please try a smaller image or check your connection.')));
              }
            });
          }
          return null;
        }
      } else {
        // Mobile: use image_picker
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return null;
        final file = picked;
        final fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        try {
          final snapshot = await ref.putData(await file.readAsBytes()).timeout(Duration(seconds: 30));
          if (context.mounted) {
          Navigator.pop(context);
          }
          return await snapshot.ref.getDownloadURL();
        } on TimeoutException {
          if (context.mounted) {
          Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload timed out. Please try a smaller image or check your connection.')));
              }
            });
          }
          return null;
        }
      }
    } catch (e) {
      print('Image pick/upload error: $e');
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick or upload image.')));
          }
        });
      }
      return null;
    }
  }

  Future<void> _showCarDialog({DocumentSnapshot? carDoc}) async {
    final isEdit = carDoc != null;
    final data = carDoc?.data() as Map<String, dynamic>?;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: data?['image'] ?? '');
    bool available = data?['available'] ?? true;
    final driverOptionsController = TextEditingController();
    final decorationOptionsController = TextEditingController();
    List<String> driverOptions = List<String>.from(data?['driverOptions'] ?? []);
    List<String> decorationOptions = List<String>.from(data?['decorationOptions'] ?? []);
    List<String> assetImages = _assetImages;
    String? selectedAssetImage = assetImages.contains(imageUrlController.text) ? imageUrlController.text : null;
    String? selectedType = data?['type'] ?? null;
    String? errorText;
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEdit ? 'Edit Car' : 'Add New Car', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  // Image Section
                  Text('Car Image', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: (imageUrlController.text.isNotEmpty)
                        ? (imageUrlController.text.startsWith('http')
                            ? Image.network(imageUrlController.text, fit: BoxFit.cover)
                            : Image.asset(imageUrlController.text, fit: BoxFit.cover))
                        : Icon(Icons.directions_car, size: 48, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.grid_view),
                          label: Text('Pick from Assets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                          onPressed: assetImages.isEmpty ? null : () async {
                            await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: 400,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                    itemCount: assetImages.length,
                                    itemBuilder: (context, idx) {
                                      final img = assetImages[idx];
                                      return GestureDetector(
                                        onTap: () {
                                          setStateDialog(() {
                                            selectedAssetImage = img;
                                            imageUrlController.text = img;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: selectedAssetImage == img ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                              width: selectedAssetImage == img ? 3 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(img, fit: BoxFit.cover),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload Image'),
                          onPressed: () async {
                            final url = await _pickAndUploadImage();
                            if (url != null) {
                              setStateDialog(() {
                                imageUrlController.text = url;
                                selectedAssetImage = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (imageUrlController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(imageUrlController.text, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 18),
                  // Car Details Section
                  Text('Car Details', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Car Name', prefixIcon: Icon(Icons.directions_car)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Car name is required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ['SUV', 'Sedan', 'Luxury', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedType = val),
                    decoration: InputDecoration(labelText: 'Car Type', prefixIcon: Icon(Icons.category)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price (FRW/day)', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Price is required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Switch(
                        value: available,
                        onChanged: (val) => setStateDialog(() => available = val),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      Text(available ? 'Available' : 'Not Available', style: TextStyle(fontWeight: FontWeight.w600, color: available ? Colors.green : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Options Section
                  Text('Driver Options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: driverOptions.map((opt) => Chip(
                      label: Text(opt),
                      onDeleted: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remove Option'),
                            content: Text('Are you sure you want to remove "$opt"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) setStateDialog(() => driverOptions.remove(opt));
                      },
                    )).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: driverOptionsController,
                          decoration: InputDecoration(hintText: 'Add driver option'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          final val = driverOptionsController.text.trim();
                          if (val.isNotEmpty && !driverOptions.contains(val)) {
                            setStateDialog(() {
                              driverOptions.add(val);
                              driverOptionsController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Decoration Options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: decorationOptions.map((opt) => Chip(
                      label: Text(opt),
                      onDeleted: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remove Option'),
                            content: Text('Are you sure you want to remove "$opt"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) setStateDialog(() => decorationOptions.remove(opt));
                      },
                    )).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: decorationOptionsController,
                          decoration: InputDecoration(hintText: 'Add decoration option'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          final val = decorationOptionsController.text.trim();
                          if (val.isNotEmpty && !decorationOptions.contains(val)) {
                            setStateDialog(() {
                              decorationOptions.add(val);
                              decorationOptionsController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorText!, style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setStateDialog(() => isLoading = true);
                                  try {
                                    final carData = {
                                      'name': nameController.text.trim(),
                                      'type': selectedType ?? '',
                                      'price': double.tryParse(priceController.text.trim()) ?? 0,
                                      'image': imageUrlController.text.trim(),
                                      'available': available,
                                      'driverOptions': driverOptions,
                                      'decorationOptions': decorationOptions,
                                    };
                                    if (isEdit) {
                                      await carDoc!.reference.update(carData);
                                    } else {
                                      await FirebaseFirestore.instance.collection('cars').add(carData);
                                    }
                                    if (context.mounted) {
                                    Navigator.pop(context);
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(isEdit ? 'Car updated successfully!' : 'Car added successfully!')),
                                          );
                                        }
                                      });
                                    }
                                  } catch (e) {
                                    setStateDialog(() {
                                      errorText = 'Failed to save car. Please try again.';
                                      isLoading = false;
                                    });
                                    if (context.mounted) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      });
                                    }
                                  }
                                },
                          child: isLoading
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(isEdit ? 'Update' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteCar(String carId) async {
    final car = FirebaseFirestore.instance.collection('cars').doc(carId);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this car? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await car.delete();
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Car deleted successfully.')));
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete car: $e'), backgroundColor: Colors.red));
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('CeremoCar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 16),
            const Text('Manage Car Listings'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('cars').orderBy('name').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No cars found.'));
          }
          final cars = snapshot.data!.docs;
          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              final data = car.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['image'] != null && data['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['image'].toString().startsWith('http')
                              ? Image.network(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.directions_car))
                              : Image.asset(data['image'], width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : Icon(Icons.directions_car, size: 40),
                  title: Text(data['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['type'] != null && data['type'].toString().isNotEmpty) Text('Type: ${data['type']}'),
                      if (data['price'] != null && data['price'].toString().isNotEmpty)
                        Text('Price: FRW${data['price']}'),
                      Text(data['available'] == true ? 'Available' : 'Not Available'),
                      if (data['driverOptions'] != null && (data['driverOptions'] as List).isNotEmpty)
                        Text('Drivers: ${(data['driverOptions'] as List).join(", ")}'),
                      if (data['decorationOptions'] != null && (data['decorationOptions'] as List).isNotEmpty)
                        Text('Decorations: ${(data['decorationOptions'] as List).join(", ")}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('FRW${data['price'] ?? ''}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        tooltip: 'Edit',
                        onPressed: () => _showCarDialog(carDoc: car),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        tooltip: 'Delete',
                        onPressed: () => _deleteCar(car.id),
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminReportsScreen extends StatefulWidget {
  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;
  String? _error;

  List<String> _statusOptions = ['All', 'PENDING', 'CONFIRMED', 'REJECTED', 'COMPLETED', 'CANCELLED'];

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> bookings) async {
    setState(() { _isExporting = true; _error = null; });
    try {
      // CSV export functionality removed for cross-platform compatibility
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export functionality is not available in this version.')),
      );
    } catch (e) {
      setState(() { _error = 'Failed to export CSV.'; });
    } finally {
      setState(() { _isExporting = false; });
    }
  }

  bool _matchesDateRange(String? dateStr) {
    if (_selectedDateRange == null || dateStr == null || dateStr.isEmpty) return true;
    try {
      final date = DateTime.parse(dateStr);
      return date.isAfter(_selectedDateRange!.start.subtract(Duration(days: 1))) &&
             date.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusOptions.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.date_range),
                  tooltip: 'Select Date Range',
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 2),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) setState(() => _selectedDateRange = picked);
                  },
                ),
                if (_selectedDateRange != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    child: Text('Clear'),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by user or car',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: _isExporting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.download),
                  label: Text('Export CSV'),
                  onPressed: _isExporting ? null : () {}, // Will be set in StreamBuilder
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No bookings found.'));
                  }
                  final allBookings = snapshot.data!.docs;
                  final bookings = allBookings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesStatus = _selectedStatus == 'All' || data['status'] == _selectedStatus;
                    final matchesSearch = _searchQuery.isEmpty || (data['userId']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) || (data['carName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                    final matchesDate = _matchesDateRange(data['date']);
                    return matchesStatus && matchesSearch && matchesDate;
                  }).toList();
                  double totalIncome = 0;
                  int completedCount = 0;
                  for (var doc in bookings) {
                    final data = (doc.data() as Map<String, dynamic>);
                    if (data['status'] == 'COMPLETED' && data['carPrice'] != null) {
                      totalIncome += double.tryParse(data['carPrice'].toString()) ?? 0;
                      completedCount++;
                    }
                  }
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text('Total Completed: $completedCount', style: theme.textTheme.bodyLarge),
                          const SizedBox(width: 24),
                        Text('Total Income: FRW${totalIncome.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            final data = booking.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('${data['carName'] ?? ''} (${data['date'] ?? ''})'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User: ${data['userId'] ?? ''}'),
                                    Text('Status: ${data['status'] ?? ''}'),
                                  if (data['carPrice'] != null) Text('Price: FRW${data['carPrice']}'),
                                    if (data['feedback'] != null) Text('Feedback: ${data['feedback']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
      ),
    );
  }
}
class AdminNotificationsScreen extends StatefulWidget {
  @override
  _AdminNotificationsScreenState createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isSending = false;
  String? _error;

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() { _isSending = true; _error = null; });
    try {
      final notification = {
        'message': _messageController.text.trim(),
        'userId': _userIdController.text.trim().isEmpty ? null : _userIdController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'SENT',
      };
      await FirebaseFirestore.instance.collection('notifications').add(notification);
      _messageController.clear();
      _userIdController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification sent.')));
    } catch (e) {
      setState(() { _error = 'Failed to send notification.'; });
    } finally {
      setState(() { _isSending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Notification', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'User ID (leave blank for all users)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              child: _isSending ? CircularProgressIndicator() : Text('Send'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: 18),
            Text('Sent Notifications', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notifications').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No notifications sent.'));
                  }
                  final notifications = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(notif['message'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notif['userId'] != null && notif['userId'].toString().isNotEmpty)
                                Text('To: ${notif['userId']}'),
                              Text('Status: ${notif['status'] ?? ''}'),
                              Text('Sent: ${notif['createdAt'] ?? ''}'),
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
    );
  }
}
class AdminProfileScreen extends StatefulWidget {
  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isEditing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (user == null) return;
    setState(() { isLoading = true; });
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      emailController.text = user!.email ?? '';
      nameController.text = doc.data()?['name'] ?? '';
      isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    setState(() { isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': nameController.text.trim(),
      });
      setState(() { isEditing = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      setState(() { error = 'Failed to update profile.'; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _updatePassword() async {
    if (user == null) return;
    if (passwordController.text.length < 6) {
      setState(() { error = 'Password must be at least 6 characters.'; });
      return;
    }
    setState(() { isLoading = true; });
    try {
      await user!.updatePassword(passwordController.text);
      passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated!')));
    } catch (e) {
      setState(() { error = 'Failed to update password.'; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile Info', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 16),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                            enabled: isEditing,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                            enabled: false,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isEditing ? _updateProfile : () => setState(() => isEditing = true),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text(isEditing ? 'Save' : 'Edit', style: const TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              if (isEditing)
                                OutlinedButton(
                                  onPressed: () => setState(() => isEditing = false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Password', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
                            obscureText: true,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _updatePassword,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Update Password', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(error!, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  const SizedBox(height: 24),
                ],
            ),
    );
  }
}

// Admin Dashboard Scaffold
class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminPremiumScreen(initialTabIndex: _selectedIndex),
      // Removed bottomNavigationBar here to avoid duplicate bars
    );
  }
}

// Placeholder screens for each admin panel
class AdminOverviewScreen extends StatelessWidget {
  Future<int> _getCount(String collection, [Map<String, dynamic>? where]) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(collection);
    if (where != null) {
      where.forEach((k, v) {
        query = query.where(k, isEqualTo: v);
      });
    }
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<double> _getTotalIncome() async {
    final bookings = await FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'COMPLETED').get();
    double total = 0;
    for (var doc in bookings.docs) {
      final data = doc.data();
      if (data['carPrice'] != null) {
        total += double.tryParse(data['carPrice'].toString()) ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, Admin!', style: theme.textTheme.displayMedium),
            const SizedBox(height: 18),
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _getCount('bookings'),
                _getCount('bookings', {'status': 'PENDING'}),
                _getCount('cars'),
                _getTotalIncome(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final totalBookings = snapshot.data![0] as int;
                final pendingRequests = snapshot.data![1] as int;
                final carsListed = snapshot.data![2] as int;
                final totalIncome = snapshot.data![3] as double;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _dashboardCard(theme, Icons.assignment, 'Total Bookings', totalBookings.toString()),
                    _dashboardCard(theme, Icons.pending_actions, 'Pending Requests', pendingRequests.toString()),
                    _dashboardCard(theme, Icons.directions_car, 'Cars Listed', carsListed.toString()),
                  _dashboardCard(theme, Icons.attach_money, 'Total Income', 'FRW${totalIncome.toStringAsFixed(2)}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text('Quick Actions', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['userId'] == null; // Admin notifications
                }).length;
              }
              return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _quickAction(context, theme, Icons.assignment, 'View Requests', '/admin_booking_requests'),
                _quickAction(context, theme, Icons.directions_car, 'Manage Cars', '/admin_manage_cars'),
                _quickAction(context, theme, Icons.bar_chart, 'Reports', '/admin_reports'),
                _quickAction(context, theme, Icons.notifications, 'Notify Users', '/admin_notifications'),
                  _quickAction(context, theme, Icons.message, 'View Notifications', '/notifications', badgeCount: unreadCount),
              ],
              );
            },
            ),
            const SizedBox(height: 24),
          ],
      ),
    );
  }

  Widget _dashboardCard(ThemeData theme, IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, ThemeData theme, IconData icon, String label, String route, {int? badgeCount}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
            children: [
              Icon(icon, size: 30, color: theme.colorScheme.secondary),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
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
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminCarListingsScreen extends StatefulWidget {
  @override
  _AdminCarListingsScreenState createState() => _AdminCarListingsScreenState();
}

class _AdminCarListingsScreenState extends State<AdminCarListingsScreen> {
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedAvailability;
  final List<String> _typeOptions = ['All', 'SUV', 'Sedan', 'Luxury', 'Pickup', 'Truck', 'Other'];
  final List<String> _availabilityOptions = ['All', 'Available', 'Not Available'];
  List<String> _assetImages = [];

  @override
  void initState() {
    super.initState();
    _loadAssetImages();
  }

  Future<void> _loadAssetImages() async {
    final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final images = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/images/') &&
            (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')) &&
            !key.endsWith('logo.png')) // Exclude logo.png
        .toList();
    setState(() {
      _assetImages = images;
    });
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      if (kIsWeb) {
        // Web: use file_picker
        final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
        if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
          print('No file picked or file is empty');
          return null;
        }
        final file = result.files.first;
        final fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        try {
          final snapshot = await ref.putData(file.bytes!).timeout(Duration(seconds: 30));
          if (context.mounted) {
            Navigator.pop(context);
          }
          return await snapshot.ref.getDownloadURL();
        } on TimeoutException {
          if (context.mounted) {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload timed out. Please try a smaller image or check your connection.')));
              }
            });
          }
          return null;
        }
      } else {
        // Mobile: use image_picker
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return null;
        final file = picked;
        final fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        try {
          final snapshot = await ref.putData(await file.readAsBytes()).timeout(Duration(seconds: 30));
          if (context.mounted) {
            Navigator.pop(context);
          }
          return await snapshot.ref.getDownloadURL();
        } on TimeoutException {
          if (context.mounted) {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload timed out. Please try a smaller image or check your connection.')));
              }
            });
          }
          return null;
        }
      }
    } catch (e) {
      print('Image pick/upload error: $e');
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick or upload image.')));
          }
        });
      }
      return null;
    }
  }

  void _editCar(DocumentSnapshot car) {
    final data = car.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name'] ?? '');
    String? selectedType = data['type'] ?? null;
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: data['image'] ?? '');
    bool available = data['available'] ?? true;
    List<String> driverOptions = List<String>.from(data['driverOptions'] ?? []);
    List<String> decorationOptions = List<String>.from(data['decorationOptions'] ?? []);
    List<String> assetImages = _assetImages;
    String? selectedAssetImage = assetImages.contains(imageUrlController.text) ? imageUrlController.text : null;
    String? errorText;
    bool isLoading = false;
    final driverOptionsController = TextEditingController();
    final decorationOptionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
        child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  Text('Edit Car', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  // Image Section
                  Text('Car Image', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: (imageUrlController.text.isNotEmpty)
                        ? (imageUrlController.text.startsWith('http')
                            ? Image.network(imageUrlController.text, fit: BoxFit.cover)
                            : Image.asset(imageUrlController.text, fit: BoxFit.cover))
                        : Icon(Icons.directions_car, size: 48, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.grid_view),
                          label: Text('Pick from Assets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                          ),
                          onPressed: assetImages.isEmpty ? null : () async {
                            await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: 400,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                    itemCount: assetImages.length,
                      itemBuilder: (context, idx) {
                                      final img = assetImages[idx];
                        return GestureDetector(
                          onTap: () {
                                          setStateDialog(() {
                                            selectedAssetImage = img;
                                            imageUrlController.text = img;
                                          });
                                          Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                              color: selectedAssetImage == img ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                              width: selectedAssetImage == img ? 3 : 1,
                              ),
                                            borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(img, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload Image'),
                          onPressed: () async {
                            final url = await _pickAndUploadImage();
                            if (url != null) {
                              setStateDialog(() {
                                imageUrlController.text = url;
                                selectedAssetImage = null;
                              });
                      }
                    },
                  ),
                      ),
                    ],
                  ),
                  if (imageUrlController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(imageUrlController.text, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 18),
                  // Car Details Section
                  Text('Car Details', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Car Name', prefixIcon: Icon(Icons.directions_car)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Car name is required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ['SUV', 'Sedan', 'Luxury', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedType = val),
                    decoration: InputDecoration(labelText: 'Car Type', prefixIcon: Icon(Icons.category)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price (FRW/day)', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Price is required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Switch(
                        value: available,
                        onChanged: (val) => setStateDialog(() => available = val),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      Text(available ? 'Available' : 'Not Available', style: TextStyle(fontWeight: FontWeight.w600, color: available ? Colors.green : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Options Section
                  Text('Driver Options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: driverOptions.map((opt) => Chip(
                      label: Text(opt),
                      onDeleted: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remove Option'),
                            content: Text('Are you sure you want to remove "$opt"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                      ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) setStateDialog(() => driverOptions.remove(opt));
                      },
                    )).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: driverOptionsController,
                          decoration: InputDecoration(hintText: 'Add driver option'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          final val = driverOptionsController.text.trim();
                          if (val.isNotEmpty && !driverOptions.contains(val)) {
                            setStateDialog(() {
                              driverOptions.add(val);
                              driverOptionsController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Decoration Options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: decorationOptions.map((opt) => Chip(
                      label: Text(opt),
                      onDeleted: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remove Option'),
                            content: Text('Are you sure you want to remove "$opt"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Remove'),
                        ),
                    ],
                  ),
                        );
                        if (confirm == true) setStateDialog(() => decorationOptions.remove(opt));
                      },
                    )).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: decorationOptionsController,
                          decoration: InputDecoration(hintText: 'Add decoration option'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          final val = decorationOptionsController.text.trim();
                          if (val.isNotEmpty && !decorationOptions.contains(val)) {
                            setStateDialog(() {
                              decorationOptions.add(val);
                              decorationOptionsController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorText!, style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setStateDialog(() => isLoading = true);
                                  try {
                                    final carData = {
                                      'name': nameController.text.trim(),
                                      'type': selectedType ?? '',
                                      'price': double.tryParse(priceController.text.trim()) ?? 0,
                                      'image': imageUrlController.text.trim(),
                                      'available': available,
                                      'driverOptions': driverOptions,
                                      'decorationOptions': decorationOptions,
                                    };
                                    await car.reference.update(carData);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    setStateDialog(() {
                                      errorText = 'Failed to save car. Please try again.';
                                      isLoading = false;
                                    });
                                  }
                                },
                          child: isLoading
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text('Update'),
                        ),
                    ),
                ],
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteCar(String carId) async {
    final car = FirebaseFirestore.instance.collection('cars').doc(carId);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this car? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await car.delete();
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Car deleted successfully.')));
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete car: $e'), backgroundColor: Colors.red));
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar and filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or type',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedType ?? 'All',
                items: _typeOptions.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                underline: SizedBox(),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedAvailability ?? 'All',
                items: _availabilityOptions.map((avail) => DropdownMenuItem(
                  value: avail,
                  child: Text(avail),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAvailability = val),
                underline: SizedBox(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            ),
            const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cars').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No cars found. Add your first car!', style: theme.textTheme.bodyLarge));
                }
                final cars = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  final available = data['available'] == true ? 'Available' : 'Not Available';
                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || type.contains(_searchQuery);
                  final matchesType = (_selectedType == null || _selectedType == 'All') || type == _selectedType!.toLowerCase();
                  final matchesAvail = (_selectedAvailability == null || _selectedAvailability == 'All') || available == _selectedAvailability;
                  return matchesSearch && matchesType && matchesAvail;
                }).toList();
                if (cars.isEmpty) {
                  return Center(child: Text('No cars match your filters.', style: theme.textTheme.bodyLarge));
                }
                return ListView.separated(
                  itemCount: cars.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final car = cars[index];
                    final data = car.data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                      color: theme.cardColor,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        leading: data['image'] != null && data['image'].toString().isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                                child: data['image'].toString().startsWith('http')
                                    ? Image.network(data['image'], width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.directions_car))
                                    : Image.asset(data['image'], width: 56, height: 56, fit: BoxFit.cover),
                              )
                            : Icon(Icons.directions_car, size: 40),
                        title: Text(data['name'] ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['type'] != null && data['type'].toString().isNotEmpty)
                              Text('Type: ${data['type']}', style: theme.textTheme.bodyMedium),
                            if (data['available'] != null)
                              Text(data['available'] == true ? 'Available' : 'Not Available', style: TextStyle(color: data['available'] == true ? Colors.green : Colors.red)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('FRW${data['price'] ?? ''}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                              tooltip: 'Edit',
                              onPressed: () => _editCar(car),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: theme.colorScheme.error),
                              tooltip: 'Delete',
                              onPressed: () => _deleteCar(car.id),
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
    );
  }
}

class MyAppTheme extends StatefulWidget {
  final Widget child;
  const MyAppTheme({required this.child, Key? key}) : super(key: key);

  static _MyAppThemeState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppThemeState>();

  @override
  _MyAppThemeState createState() => _MyAppThemeState();
}

class _MyAppThemeState extends State<MyAppTheme> {
  ThemeMode _themeMode = ThemeMode.system;

  void updateThemeMode(ThemeMode mode) {
    if (mounted) {
    setState(() { _themeMode = mode; });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
      if (mounted) {
    setState(() {
      if (mode == 'light') _themeMode = ThemeMode.light;
      else if (mode == 'dark') _themeMode = ThemeMode.dark;
      else _themeMode = ThemeMode.system;
    });
      }
    } catch (e) {
      // Fallback to system theme if there's an error
      if (mounted) {
        setState(() {
          _themeMode = ThemeMode.system;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CeremoCar',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.deepBlue,
          onPrimary: AppColors.textLight,
          secondary: AppColors.coral,
          onSecondary: AppColors.textLight,
          background: AppColors.softGray,
          onBackground: AppColors.textDark,
          surface: AppColors.cardWhite,
          onSurface: AppColors.textDark,
          error: AppColors.accentRed,
          onError: AppColors.textLight,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.softGray,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
            shadowColor: AppColors.deepBlue.withOpacity(0.15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.cardWhite,
            foregroundColor: AppColors.coral,
            side: BorderSide(color: AppColors.coral, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.deepBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardWhite,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.deepBlue,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDark),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.deepBlue,
          onPrimary: AppColors.textLight,
          secondary: AppColors.coral,
          onSecondary: AppColors.textLight,
          background: AppColors.darkBg,
          onBackground: AppColors.darkText,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.accentRed,
          onError: AppColors.textLight,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.darkBg,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
            shadowColor: AppColors.deepBlue.withOpacity(0.15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.darkSurface,
            foregroundColor: AppColors.coral,
            side: BorderSide(color: AppColors.coral, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.coral,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: TextStyle(color: AppColors.darkMuted, fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.textLight,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textLight),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkMuted),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textLight),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkMuted),
        ),
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/available_cars_screen': (context) => AvailableCarsScreen(),
        '/car_details_screen': (context) => CarDetailsScreen(),
        '/my_bookings_screen': (context) => MyBookingsScreen(),
        '/booking_confirmation_screen': (context) => BookingConfirmationScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin_dashboard': (context) => AdminDashboardScreen(),
        '/admin_manage_cars': (context) => AdminManageCarsScreen(),
        '/admin_reports': (context) => AdminReportsScreen(),
        '/admin_notifications': (context) => AdminNotificationsScreen(),
        '/admin_profile': (context) => AdminProfileScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/booking_cancellation_screen': (context) => BookingCancellationScreen(),
        '/payment_screen': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final bookingData = args != null && args['bookingData'] != null ? args['bookingData'] as Map<String, dynamic> : <String, dynamic>{};
          final amount = args != null && args['amount'] != null ? (args['amount'] as num).toDouble() : 0.0;
          return PaymentScreen(bookingData: bookingData, amount: amount);
        },
        '/subscription': (context) => SubscriptionScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyAppTheme(child: CeremoCarApp()));
}

class AppColors {
  static const deepBlue = Color(0xFF3B5BFE);
  static const coral = Color(0xFFF76C5E);
  static const softGray = Color(0xFFF8F9FB);
  static const cardWhite = Color(0xFFFFFFFF);
  static const accentYellow = Color(0xFFFFD600);
  static const accentGreen = Color(0xFF4CAF50);
  static const accentRed = Color(0xFFF44336);
  static const textDark = Color(0xFF222B45);
  static const textLight = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFB0B3B8);
  // Dark mode colors
  static const darkBg = Color(0xFF181A20);
  static const darkSurface = Color(0xFF23243A);
  static const darkCard = Color(0xFF23243A);
  static const darkText = Color(0xFFE5E7EB);
  static const darkMuted = Color(0xFF8A8D9F);
}

class CeremoCarApp extends StatelessWidget {
  final ThemeMode themeMode;
  const CeremoCarApp({this.themeMode = ThemeMode.system});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CeremoCar',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.deepBlue,
          onPrimary: AppColors.textLight,
          secondary: AppColors.coral,
          onSecondary: AppColors.textLight,
          background: AppColors.softGray,
          onBackground: AppColors.textDark,
          surface: AppColors.cardWhite,
          onSurface: AppColors.textDark,
          error: AppColors.accentRed,
          onError: AppColors.textLight,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.softGray,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
            shadowColor: AppColors.deepBlue.withOpacity(0.15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.cardWhite,
            foregroundColor: AppColors.coral,
            side: BorderSide(color: AppColors.coral, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.deepBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardWhite,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.deepBlue,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDark),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.deepBlue,
          onPrimary: AppColors.textLight,
          secondary: AppColors.coral,
          onSecondary: AppColors.textLight,
          background: AppColors.darkBg,
          onBackground: AppColors.darkText,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.accentRed,
          onError: AppColors.textLight,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.darkBg,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
            shadowColor: AppColors.deepBlue.withOpacity(0.15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.darkSurface,
            foregroundColor: AppColors.coral,
            side: BorderSide(color: AppColors.coral, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5),
            minimumSize: const Size(56, 56),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.coral,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: TextStyle(color: AppColors.darkMuted, fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.textLight,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textLight),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkMuted),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textLight),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkMuted),
        ),
      ),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/available_cars_screen': (context) => AvailableCarsScreen(),
        '/car_details_screen': (context) => CarDetailsScreen(),
        '/my_bookings_screen': (context) => MyBookingsScreen(),
        '/booking_confirmation_screen': (context) => BookingConfirmationScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin_dashboard': (context) => AdminDashboardScreen(),
        '/admin_manage_cars': (context) => AdminManageCarsScreen(),
        '/admin_reports': (context) => AdminReportsScreen(),
        '/admin_notifications': (context) => AdminNotificationsScreen(),
        '/admin_profile': (context) => AdminProfileScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/booking_cancellation_screen': (context) => BookingCancellationScreen(),
        '/payment_screen': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final bookingData = args != null && args['bookingData'] != null ? args['bookingData'] as Map<String, dynamic> : <String, dynamic>{};
          final amount = args != null && args['amount'] != null ? (args['amount'] as num).toDouble() : 0.0;
          return PaymentScreen(bookingData: bookingData, amount: amount);
        },
        '/subscription': (context) => SubscriptionScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
