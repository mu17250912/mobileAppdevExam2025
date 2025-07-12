import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // For Product model
import 'rwanda_colors.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();

  Product? _editingProduct;

  CollectionReference get _productsRef => FirebaseFirestore.instance.collection('products');

  void _addOrUpdateProduct() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (name.isEmpty) return;
    try {
      if (_editingProduct == null) {
        await _productsRef.add({
          'name': name,
          'description': desc,
          'price': price,
          'quantity': qty,
        });
      } else {
        await _productsRef.doc(_editingProduct!.id).update({
          'name': name,
          'description': desc,
          'price': price,
          'quantity': qty,
        });
        _editingProduct = null;
      }
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _qtyController.clear();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save product: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _editingProduct = product;
      _nameController.text = product.name;
      _descController.text = product.description;
      _priceController.text = product.price.toString();
      _qtyController.text = product.quantity.toString();
    });
  }

  void _deleteProduct(Product product) async {
    await _productsRef.doc(product.id).delete();
    if (_editingProduct?.id == product.id) {
      setState(() {
        _editingProduct = null;
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        _qtyController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: Row(
          children: [
            const Text('Product Management', style: TextStyle(color: Colors.white)),
            const Spacer(),
            Icon(Icons.wb_sunny, color: kRwandaSun, size: 28),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRwandaYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              onPressed: _addOrUpdateProduct,
              child: Text(_editingProduct == null ? 'Add Product' : 'Update Product'),
            ),
            const SizedBox(height: 20),
            const Text('Product List', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }
                  final products = docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        color: kRwandaGreen.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: ListTile(
                          title: Text(product.name, style: TextStyle(color: kRwandaBlue, fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${product.quantity} | Price: ${product.price}\n${product.description}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: kRwandaYellow),
                                onPressed: () => _editProduct(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteProduct(product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 