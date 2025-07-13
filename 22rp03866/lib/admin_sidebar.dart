import 'package:flutter/material.dart';
import 'theme/colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.book_online, 'label': 'Bookings'},
      {'icon': Icons.park, 'label': 'Parks'},
      {'icon': Icons.people, 'label': 'Users'},
      {'icon': Icons.logout, 'label': 'Logout'},
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo or App Name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Icon(Icons.travel_explore, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final selected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Material(
                color: selected ? AppColors.sidebarSelected : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    items[index]['icon'] as IconData,
                    color: selected ? AppColors.primary : AppColors.sidebarIcon,
                  ),
                  title: Text(
                    items[index]['label'] as String,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: selected,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => onItemSelected(index),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
} 