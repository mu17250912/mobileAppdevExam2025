import 'package:flutter/material.dart';
import '../models/product.dart';
import 'order_request_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                color: Color(0xFF2E8B57),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text('Description: ${product.description}'),
            const SizedBox(height: 8),
            Text('Location: ${product.location}'),
            const SizedBox(height: 8),
            Text('Quantity: ${product.quantity} ${product.unit} available'),
            const SizedBox(height: 8),
            Text('Price: ${product.price} RWF per ${product.unit}'),
            const SizedBox(height: 8),
            Text('Harvest Date: ${product.harvestDate}'),
            const SizedBox(height: 8),
            Text('Freshness: Very Fresh'),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Farmer Contact',
                    style: TextStyle(
                      color: Color(0xFF2E8B57),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${product.farmerName}'),
                  Text('Phone: ${product.farmerPhone}'),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${product.rating} / 5'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderRequestScreen(product: product),
                    ),
                  );
                },
                child: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 