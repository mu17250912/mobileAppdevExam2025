import 'package:flutter/material.dart';
import 'booking_screen.dart';

class BookingMainScreen extends StatefulWidget {
  const BookingMainScreen({super.key});

  @override
  State<BookingMainScreen> createState() => _BookingMainScreenState();
}

class _BookingMainScreenState extends State<BookingMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const BookingScreen(),
    Center(child: Text('My Bookings (Coming Soon)', style: TextStyle(fontSize: 18))),
    Center(child: Text('Booking History (Coming Soon)', style: TextStyle(fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Book Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              tooltip: 'New Booking',
            )
          : null,
    );
  }
} 