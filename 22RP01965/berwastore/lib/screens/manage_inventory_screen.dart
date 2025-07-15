import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageInventoryScreen extends StatelessWidget {
  const ManageInventoryScreen({Key? key}) : super(key: key);

  Future<void> _deleteProduct(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    String name = data['name'] ?? '';
    String price = data['price'] ?? '';
    String category = data['category'] ?? '';
    String size = data['size'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  onChanged: (val) => name = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
                ),
                TextFormField(
                  initialValue: price,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => price = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter price' : null,
                ),
                TextFormField(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (val) => category = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter category' : null,
                ),
                TextFormField(
                  initialValue: size,
                  decoration: const InputDecoration(labelText: 'Size'),
                  onChanged: (val) => size = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter size' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await FirebaseFirestore.instance.collection('products').doc(docId).update({
                  'name': name,
                  'price': price,
                  'category': category,
                  'size': size,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product updated successfully!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Inventory')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading inventory.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          final products = snapshot.data!.docs;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final doc = products[i];
              final data = doc.data() as Map<String, dynamic>;
              return Dismissible(
                key: Key(doc.id),
                background: Container(color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteProduct(doc.id, context),
                child: ListTile(
                  leading: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                      ? (data['imageUrl'].toString().startsWith('http')
                          ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                          : Image.asset(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover))
                      : const Icon(Icons.image, size: 40),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text('Category: ${data['category'] ?? ''}\nPrice: RWF ${data['price'] ?? ''}\nSize: ${data['size'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(context, doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(doc.id, context),
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