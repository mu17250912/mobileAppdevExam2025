import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  Future<void> _editProduct(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final quantityController = TextEditingController(text: data['quantity']?.toString() ?? '');
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    String? unit = data['unit'];
    final units = ['kg', 'l', 'pcs', 'g', 'ml'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => unit = val,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price per Unit (RWF)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'name': nameController.text.trim(),
                'quantity': double.tryParse(quantityController.text.trim()) ?? 0,
                'unit': unit,
                'price': double.tryParse(priceController.text.trim()) ?? 0,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    final userId = userProvider.userData?['uid'];
    if (userType == null) {
      return const Scaffold(body: Center(child: Text('User type not found.')));
    }
    if (userType == 'Buyer') {
      return const Scaffold(body: Center(child: Text('Access denied.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Products')),
      body: StreamBuilder<QuerySnapshot>(
        stream: userType == 'Admin'
            ? FirebaseFirestore.instance.collection('products').snapshots()
            : FirebaseFirestore.instance.collection('products').where('farmerId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not listed any products yet.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('Price: RWF ${data['price']} | Qty: ${data['quantity']} ${data['unit'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editProduct(docs[i]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(docs[i]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 