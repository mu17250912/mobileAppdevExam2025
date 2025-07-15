import 'package:flutter/material.dart';

class BookingForm extends StatelessWidget {
  const BookingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Number of seats to book',
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Number of Seats',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 16),
          Semantics(
            label: 'Special requests or notes',
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Special Requests',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          SizedBox(height: 16),
          Semantics(
            label: 'Confirm booking button',
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Booking confirmed!')));
              },
              child: Text('Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
