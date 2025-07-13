import 'package:flutter/material.dart';

class TodaysOverview extends StatelessWidget {
  final int products;
  final int orders;
  final int sales;
  final int views;
  final VoidCallback? onProductsTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onSalesTap;
  final VoidCallback? onViewsTap;

  const TodaysOverview({
    Key? key,
    required this.products,
    required this.orders,
    required this.sales,
    required this.views,
    this.onProductsTap,
    this.onOrdersTap,
    this.onSalesTap,
    this.onViewsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Today's Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            GestureDetector(
              onTap: onProductsTap,
              child: _OverviewCard(
                color: Colors.green.shade50,
                icon: Icons.inventory_2,
                iconColor: Colors.green,
                value: products.toString(),
                label: 'Products',
                valueColor: Colors.green,
              ),
            ),
            GestureDetector(
              onTap: onOrdersTap,
              child: _OverviewCard(
                color: Colors.orange.shade50,
                icon: Icons.shopping_cart,
                iconColor: Colors.orange,
                value: orders.toString(),
                label: 'Orders',
                valueColor: Colors.orange,
              ),
            ),
            GestureDetector(
              onTap: onSalesTap,
              child: _OverviewCard(
                color: Colors.blue.shade50,
                icon: Icons.attach_money,
                iconColor: Colors.blue,
                value: 'RWF $sales',
                label: 'Sales',
                valueColor: Colors.blue,
              ),
            ),
            GestureDetector(
              onTap: onViewsTap,
              child: _OverviewCard(
                color: Colors.purple.shade50,
                icon: Icons.remove_red_eye,
                iconColor: Colors.purple,
                value: views.toString(),
                label: 'Views',
                valueColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color valueColor;

  const _OverviewCard({
    Key? key,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
} 