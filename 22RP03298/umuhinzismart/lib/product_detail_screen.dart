import 'package:flutter/material.dart';
import 'models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = (product.name.isNotEmpty) ? product.name : 'No name';
    final description = (product.description.isNotEmpty) ? product.description : 'No description';
    final imageUrl = (product.imageUrl.isNotEmpty) ? product.imageUrl : 'https://via.placeholder.com/300x200?text=No+Image';
    final category = (product.category.isNotEmpty) ? product.category : 'Unknown';
    final dealer = (product.dealer.isNotEmpty) ? product.dealer : 'Unknown';
    final stock = product.stock != null ? product.stock.toString() : 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            Text('Price: \u0024${product.price}'),
            const SizedBox(height: 8),
            Text('Category: $category'),
            const SizedBox(height: 8),
            Text('Dealer: $dealer'),
            const SizedBox(height: 8),
            Text('Stock: $stock'),
          ],
        ),
      ),
    );
  }
}
