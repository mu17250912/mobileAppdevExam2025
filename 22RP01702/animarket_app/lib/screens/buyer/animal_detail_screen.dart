import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_item.dart';
import '../../utils/constants.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Animal animal;
  final bool isSeller;

  const AnimalDetailScreen({Key? key, required this.animal, required this.isSeller}) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late double price;

  @override
  void initState() {
    super.initState();
    price = widget.animal.price;
  }

  void updatePrice(double newPrice) async {
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await animalProvider.updateAnimalPrice(widget.animal.id, newPrice);

    notificationProvider.addNotification(NotificationItem(
      emoji: _getEmoji(widget.animal.type),
      title: "Price Changed",
      message: "Price for ${widget.animal.type} in ${widget.animal.location} was ${newPrice > price ? 'increased' : 'decreased'} to RWF $newPrice.",
      timestamp: TimeOfDay.now().format(context),
      animalId: widget.animal.id,
      unread: true,
    ));

    setState(() {
      price = newPrice;
    });
  }

  void deleteAnimal() async {
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    await animalProvider.removeAnimal(widget.animal.id);
    Navigator.of(context).pop();
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

  Future<void> _openWhatsApp(String phone, String animalType) async {
    String normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!normalizedPhone.startsWith('250')) {
      normalizedPhone = '250' + normalizedPhone.replaceFirst(RegExp(r'^0+'), '');
    }
    final message = Uri.encodeComponent("Hello, I'm interested in your $animalType listed on AniMarket.");
    String url;
    // Use WhatsApp Web for non-mobile platforms
    if (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) {
      url = 'https://wa.me/$normalizedPhone?text=$message';
    } else {
      url = 'https://web.whatsapp.com/send?phone=$normalizedPhone&text=$message';
    }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    return Scaffold(
      appBar: AppBar(
        title: Text('${animal.type} Details'),
        backgroundColor: kPrimaryGreen,
        actions: [
          if (widget.isSeller)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Delete Animal'),
                    content: Text('Are you sure you want to delete this animal?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) deleteAnimal();
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getEmoji(animal.type), style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Type: ${animal.type}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Location: ${animal.location}', style: TextStyle(fontSize: 18)),
            Text('Description: ${animal.description}', style: TextStyle(fontSize: 16)),
            Text('Seller: ${animal.sellerName}', style: TextStyle(fontSize: 16)),
            Text('Phone: ${animal.sellerPhone}', style: TextStyle(fontSize: 16)),
            Text('Number of Animals: ${animal.count}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            Text('Price: RWF ${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
            Spacer(),
            if (!widget.isSeller)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.chat),
                  label: Text('Chat with Seller on WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _openWhatsApp(animal.sellerPhone, animal.type);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
