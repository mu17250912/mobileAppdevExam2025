import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AnimalCard extends StatelessWidget {
  final String emoji;
  final String type;
  final double price;
  final String location;
  final String seller;
  final VoidCallback onView;
  final VoidCallback onChat;

  const AnimalCard({
    Key? key,
    required this.emoji,
    required this.type,
    required this.price,
    required this.location,
    required this.seller,
    required this.onView,
    required this.onChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 48)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$type - KES ${price.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkText)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: kPrimaryGreen),
                      SizedBox(width: 4),
                      Text(location, style: TextStyle(color: kGrayText)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Seller: $seller', style: TextStyle(color: kGrayText)),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    minimumSize: Size(80, 36),
                  ),
                  child: Text('View'),
                ),
                SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onChat,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    side: BorderSide(color: kPrimaryGreen),
                    minimumSize: Size(80, 36),
                  ),
                  child: Text('💬 Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
