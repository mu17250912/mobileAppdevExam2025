import 'package:flutter/material.dart';

class ServiceSelectionPage extends StatelessWidget {
  const ServiceSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Service', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF6A8DFF), size: 20),
              SizedBox(width: 2),
              Text('New York, NY', style: TextStyle(color: Colors.black54, fontSize: 15)),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Residential Cleaning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: const [
                _ServiceCard(
                  icon: Icons.home,
                  title: 'Regular Cleaning',
                  description: 'Standard house cleaning service',
                  price: 'Starting at \$80',
                ),
                _ServiceCard(
                  icon: Icons.auto_awesome,
                  title: 'Deep Cleaning',
                  description: 'Thorough cleaning for all areas',
                  price: 'Starting at \$150',
                ),
                _ServiceCard(
                  icon: Icons.inventory,
                  title: 'Move-in/out',
                  description: 'Complete cleaning for moving',
                  price: 'Starting at \$200',
                ),
                _ServiceCard(
                  icon: Icons.window,
                  title: 'Window Cleaning',
                  description: 'Interior and exterior windows',
                  price: 'Starting at \$60',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Commercial Cleaning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: const [
                _ServiceCard(
                  icon: Icons.apartment,
                  title: 'Office Cleaning',
                  description: 'Professional office maintenance',
                  price: 'Starting at \$120',
                ),
                _ServiceCard(
                  icon: Icons.store,
                  title: 'Retail Cleaning',
                  description: 'Store and showroom cleaning',
                  price: 'Starting at \$100',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  const _ServiceCard({required this.icon, required this.title, required this.description, required this.price});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: BookServicePage(
                  icon: icon,
                  serviceTitle: title,
                  serviceDescription: description,
                  price: price,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6A8DFF),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const Spacer(),
              Text(price, style: const TextStyle(color: Color(0xFF6A8DFF), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
} 