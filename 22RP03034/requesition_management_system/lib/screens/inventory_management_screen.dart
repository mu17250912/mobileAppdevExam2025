import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  String _categoryFilter = 'All';
  final List<String> _categories = ['All', 'Tool', 'Material'];

  @override
  Widget build(BuildContext context) {
    List<InventoryItem> filteredItems = _categoryFilter == 'All'
        ? InventoryStore.items
        : InventoryStore.items.where((item) => item.category == _categoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Filter by category: '),
                DropdownButton<String>(
                  value: _categoryFilter,
                  items: _categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryFilter = value!;
                    });
                  },
                ),
                const Spacer(),
                Text('Total Items: ${filteredItems.length}'),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('No inventory items found.'))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      Color stockColor = item.quantity > 10
                          ? Colors.green
                          : item.quantity > 0
                              ? Colors.orange
                              : Colors.red;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            item.category == 'Tool' ? Icons.build : Icons.inventory,
                            color: stockColor,
                          ),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.quantity} ${item.unit}'),
                              Text(item.description, style: const TextStyle(fontSize: 12)),
                              if (item.location != null)
                                Text('Location: ${item.location}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(item.category),
                                backgroundColor: item.category == 'Tool' ? Colors.blue.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit':
                                      _showEditItemDialog(context, item);
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmation(context, item);
                                      break;
                                    case 'add_stock':
                                      _showAddStockDialog(context, item);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'add_stock', child: Text('Add Stock')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'Tool';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) => value!.isEmpty ? 'Enter item name' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Tool', 'Material']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) => selectedCategory = value!,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'Enter description' : null,
                ),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
                ),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit (pcs, kg, m, etc.)'),
                  validator: (value) => value!.isEmpty ? 'Enter unit' : null,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location (optional)'),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final item = InventoryItem(
                  id: InventoryStore.generateId(),
                  name: nameController.text,
                  category: selectedCategory,
                  description: descriptionController.text,
                  quantity: int.parse(quantityController.text),
                  unit: unitController.text,
                  dateAdded: DateTime.now(),
                  addedBy: 'Logistics Manager',
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                InventoryStore.addItem(item);
                NotificationStore.add('Item Added', '${item.name} added to inventory.');
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, InventoryItem item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);
    final locationController = TextEditingController(text: item.location ?? '');
    final notesController = TextEditingController(text: item.notes ?? '');
    String selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Inventory Item'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) => value!.isEmpty ? 'Enter item name' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Tool', 'Material']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) => selectedCategory = value!,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'Enter description' : null,
                ),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
                ),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  validator: (value) => value!.isEmpty ? 'Enter unit' : null,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedItem = InventoryItem(
                  id: item.id,
                  name: nameController.text,
                  category: selectedCategory,
                  description: descriptionController.text,
                  quantity: int.parse(quantityController.text),
                  unit: unitController.text,
                  dateAdded: item.dateAdded,
                  addedBy: item.addedBy,
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                InventoryStore.updateItem(updatedItem);
                NotificationStore.add('Item Updated', '${updatedItem.name} updated.');
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, InventoryItem item) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock to ${item.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                              Text('Current stock: $item.quantity $item.unit'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity to add ($item.unit)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantityToAdd = int.parse(quantityController.text);
                InventoryStore.updateStock(item.name, quantityToAdd, false);
                NotificationStore.add('Stock Added', '${quantityToAdd} ${item.unit} added to ${item.name}.');
                
                // Check if any pending requests can now be processed
                _checkPendingRequestsForItem(item.name);
                
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Check pending requests for a specific item when stock is added
  void _checkPendingRequestsForItem(String itemName) async {
    // Fetch requests from Firestore
    final snapshot = await FirebaseFirestore.instance.collection('requests').get();
    final requests = snapshot.docs
        .map((doc) => Request.fromFirestore(doc.data(), doc.id))
        .where((r) => r.status == 'Pending' && r.subject.toLowerCase() == itemName.toLowerCase())
        .toList();
    
    if (requests.isNotEmpty) {
      final inventoryItem = InventoryStore.findItemByName(itemName);
      if (inventoryItem != null) {
        for (final request in requests) {
          int requestedQuantity;
          try {
            requestedQuantity = int.parse(request.quantity ?? '1');
          } catch (e) {
            requestedQuantity = 1;
          }
          
          if (inventoryItem.quantity >= requestedQuantity) {
            // Item is now in stock - auto-accept and forward to approver
            request.status = 'For Approval';
            request.logisticsComment = 'Item now in stock - auto-accepted and forwarded to approver';
            request.addHistory('For Approval', 'Logistics', 'Item now in stock - auto-accepted');
            
            // Update in Firestore
            await FirebaseFirestore.instance.collection('requests').doc(request.id).update(request.toMap());
            
            NotificationStore.add('Pending Request Updated', 'Request "${request.subject}" is now in stock and forwarded to approver.');
          }
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              InventoryStore.removeItem(item.id);
              NotificationStore.add('Item Deleted', '${item.name} removed from inventory.');
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 