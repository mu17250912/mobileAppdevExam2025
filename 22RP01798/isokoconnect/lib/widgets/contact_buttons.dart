// Contact Buttons Widget Placeholder
import 'package:flutter/material.dart';

class ContactButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: Text('Call'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {},
          child: Text('WhatsApp'),
        ),
      ],
    );
  }
} 