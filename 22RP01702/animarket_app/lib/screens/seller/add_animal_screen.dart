import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../common/success_screen.dart';
import '../seller/seller_dashboard.dart';
import 'package:provider/provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/animal.dart';
import '../../models/notification_item.dart';

class AddAnimalScreen extends StatefulWidget {
  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  String? type;
  String? description;
  double? price;
  bool? vaccinated;
  int? count;
  bool isLoading = false;
  late TextEditingController locationController;
  late TextEditingController countController;
  bool isPremium = false;

  final List<String> animalTypes = ['Cow', 'Chicken', 'Goat', 'Pig'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    locationController = TextEditingController(text: user?.location ?? '');
    countController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    locationController.dispose();
    countController.dispose();
    super.dispose();
  }

  void _postAnimal() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final user = authProvider.user;

    // Check seller limit
    if (user != null && !user.isPremium) {
      final sellerAnimals = await animalProvider.getSellerAnimalsCount(user.id);
      if (sellerAnimals >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade to premium to add more than 3 animals.')),
        );
        return;
      }
    }

    if (_formKey.currentState!.validate() && type != null && vaccinated != null) {
      setState(() => isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in.')),
        );
        setState(() => isLoading = false);
        return;
      }
      final animal = Animal(
        id: '', // Firestore will assign ID
        userId: user.id,
        type: type!,
        location: locationController.text,
        description: description!,
        price: price!,
        sellerName: user.name,
        sellerPhone: user.phone,
        createdAt: DateTime.now(),
        count: int.tryParse(countController.text) ?? 1,
        isPremium: isPremium,
      );
      final animalId = await animalProvider.addAnimal(animal);

      // Notification
      final now = DateTime.now();
      final timestamp = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

      // Seller notification
      notificationProvider.addNotification(NotificationItem(
        emoji: _getEmoji(animal.type),
        title: "Animal(s) Added",
        message: "You added ${animal.count} ${animal.type}${animal.count > 1 ? 's' : ''}.",
        timestamp: timestamp,
        animalId: animalId,
        unread: true,
      ));

      // Buyer notification (simulate for demo: add to buyer's provider as well)
      notificationProvider.addNotification(NotificationItem(
        emoji: _getEmoji(animal.type),
        title: "New ${animal.type} Added",
        message: "${animal.count} ${animal.type}${animal.count > 1 ? 's' : ''} added in ${animal.location} by ${animal.sellerName}.",
        timestamp: timestamp,
        animalId: animalId, // <-- This must be set!
        unread: true,
      ));

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Animal posted successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            message: 'Your animal has been posted successfully!',
            nextScreen: SellerDashboard(initialTabIndex: 2),
          ),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Add Animal', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TODO: Add photo upload widget
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Animal Type',
                  border: OutlineInputBorder(),
                ),
                items: animalTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => type = value),
                validator: (value) => value == null ? 'Select animal type' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Price (RWF)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter price';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Enter valid price';
                  return null;
                },
                onChanged: (value) => price = double.tryParse(value),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: countController,
                decoration: InputDecoration(
                  labelText: 'Number of Animals',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter number of animals';
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed < 1) return 'Enter a valid number';
                  return null;
                },
                onChanged: (value) => count = int.tryParse(value),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Enter description' : null,
                onChanged: (value) => description = value,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Vaccinated:', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 16),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Yes'),
                      value: true,
                      groupValue: vaccinated,
                      onChanged: (value) => setState(() => vaccinated = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('No'),
                      value: false,
                      groupValue: vaccinated,
                      onChanged: (value) => setState(() => vaccinated = value),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              isLoading
                  ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGreen))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _postAnimal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Post Animal', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
