import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: StreamBuilder<List<String>>(
        stream: authService.favoriteProductIds,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favoriteIds = snapshot.data ?? [];
          if (favoriteIds.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }
          return StreamBuilder<List<Product>>(
            stream: productService.getProducts(),
            builder: (context, productSnapshot) {
              if (!productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = productSnapshot.data!
                  .where((p) => favoriteIds.contains(p.id))
                  .toList();
              if (products.isEmpty) {
                return const Center(child: Text('No favorites found.'));
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    leading: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                    title: Text(product.name),
                    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          tooltip: 'Add to Cart',
                          onPressed: () {
                            cartService.addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: Colors.green),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Remove from Favorites',
                          onPressed: () {
                            authService.removeFavorite(product.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 