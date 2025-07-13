import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final String title, category, location, budget;
  final VoidCallback? onTap;
  const JobCard({
    required this.title,
    required this.category,
    required this.location,
    required this.budget,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.work, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Chip(label: Text(category)),
            const SizedBox(width: 8),
            Chip(label: Text(location)),
          ],
        ),
        trailing: Text(budget, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        onTap: onTap,
      ),
    );
  }
}
