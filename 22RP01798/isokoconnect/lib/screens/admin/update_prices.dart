import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

class UpdatePricesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Prices')),
      body: StreamBuilder<List<ProductModel>>(
        stream: FirestoreService().getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final priceController = TextEditingController(text: product.pricePerKg.toString());
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Current Price: ${product.pricePerKg} RWF/kg'),
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Price'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          final newPrice = double.tryParse(priceController.text.trim());
                          if (newPrice == null) return;
                          try {
                            final updatedProduct = ProductModel(
                              id: product.id,
                              name: product.name,
                              pricePerKg: newPrice,
                              quantity: product.quantity,
                              sellerId: product.sellerId,
                              sellerName: product.sellerName,
                              sellerPhone: product.sellerPhone,
                              sellerDistrict: product.sellerDistrict,
                              sellerSector: product.sellerSector,
                              createdAt: product.createdAt,
                              updatedAt: DateTime.now(),
                            );
                            await FirestoreService().updateProduct(updatedProduct);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price updated.')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 