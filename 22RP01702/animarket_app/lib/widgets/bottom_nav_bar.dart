import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isSeller;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.isSeller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: kGrayText,
      backgroundColor: Colors.white,
      onTap: onTap,
      items: isSeller
          ? [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listings'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ]
          : [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
