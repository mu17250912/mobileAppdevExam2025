import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/animal_provider.dart';
import 'animal_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              notificationProvider.markAllRead();
            },
            child: Text('Mark all read', style: TextStyle(color: kAccentYellow)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications yet.'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  color: n.unread ? kLightGreen.withOpacity(0.2) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Text(n.emoji, style: TextStyle(fontSize: 32)),
                    title: Text(n.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n.message),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(n.timestamp, style: TextStyle(color: kGrayText, fontSize: 12)),
                        if (n.unread)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: kPrimaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      if (n.animalId != null) {
                        final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
                        final animal = await animalProvider.getAnimalById(n.animalId!);
                        if (animal != null) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => AnimalDetailScreen(animal: animal, isSeller: false), // isSeller: false for buyers
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Animal not found.')),
                          );
                        }
                      }
                      notificationProvider.markAsRead(index);
                    },
                  ),
                );
              },
            ),
    );
  }
}
