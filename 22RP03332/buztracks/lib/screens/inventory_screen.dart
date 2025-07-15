import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../services/print_service.dart';
import '../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String _searchQuery = '';
  bool _isAddingProduct = false;
  String? _editingProductId;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  
  final Color mainColor = const Color(0xFFFFD600); // Lightning yellow
  final FirestoreService _firestoreService = FirestoreService();
  final PrintService _printService = PrintService();
  
  // Store category keys, not localized strings
  final List<String> _categoryKeys = [
    'categoryGrains',
    'categoryBeverages',
    'categoryCooking',
    'categoryVegetables',
    'categoryDairy',
    'categoryBakery',
    'categoryFruits',
    'categoryMeat',
  ];

  // Local map for category display names by language
  static const Map<String, Map<String, String>> _categoryDisplayNames = {
    'en': {
      'categoryGrains': 'Grains',
      'categoryBeverages': 'Beverages',
      'categoryCooking': 'Cooking',
      'categoryVegetables': 'Vegetables',
      'categoryDairy': 'Dairy',
      'categoryBakery': 'Bakery',
      'categoryFruits': 'Fruits',
      'categoryMeat': 'Meat',
    },
    'fr': {
      'categoryGrains': 'Céréales',
      'categoryBeverages': 'Boissons',
      'categoryCooking': 'Cuisine',
      'categoryVegetables': 'Légumes',
      'categoryDairy': 'Produits laitiers',
      'categoryBakery': 'Boulangerie',
      'categoryFruits': 'Fruits',
      'categoryMeat': 'Viande',
    },
  };

  String localizedCategory(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return _categoryDisplayNames[lang]?[key] ?? _categoryDisplayNames['en']![key] ?? key;
  }

  List<String> get _categories => _categoryKeys.map((key) => localizedCategory(context, key)).toList();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    _firestoreService.getProductsStream().listen((products) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((product) {
      return product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             product['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addProduct() {
    setState(() {
      _isAddingProduct = true;
      _editingProductId = null;
    });
    _resetForm();
  }

  void _editProduct(int index) {
    final product = _filteredProducts[index];
    setState(() {
      _isAddingProduct = true;
      _editingProductId = product['id'];
    });
    _nameController.text = product['name'];
    _priceController.text = product['price'].toString();
    _stockController.text = product['stock'].toString();
    // Store the key, not the localized string
    _categoryController.text = product['category'];
  }

  void _deleteProduct(int index) async {
    final product = _filteredProducts[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProduct),
        content: Text('${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteProduct(product['id']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.productDeleted)),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingProduct}: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> addProductDirectly(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .add({
          ...product,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = {
      'name': _nameController.text,
      'price': int.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
      // Store the key, not the localized string
      'category': _categoryController.text,
      'minStock': 10, // Default minimum stock
    };

    try {
      await addProductDirectly(product); // <-- This uses Firestore directly
      
      setState(() {
        _isAddingProduct = false;
      });
      
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingProductId != null ? AppLocalizations.of(context)!.productUpdated : AppLocalizations.of(context)!.productAdded)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorSavingProduct}: $e')),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _categoryController.clear();
  }

  void _updateStock(int index, int newStock) async {
    final product = _filteredProducts[index];
    try {
      await _firestoreService.updateProduct(product['id'], {'stock': newStock});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated to $newStock')), // TODO: Replace with loc.stockUpdated if added to ARB
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock: $e')), // TODO: Replace with loc.errorUpdatingStock if added to ARB
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.inventory),
        backgroundColor: mainColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Inventory Summary'), // TODO: Replace with loc.inventorySummary if added to ARB
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Products: ${_products.length}'), // TODO: Replace with loc.totalProducts if added to ARB
                      Text('Low Stock Items: ${_products.where((p) => (p['stock'] as int) <= (p['minStock'] as int)).length}'), // TODO: Replace with loc.lowStock if added to ARB
                      Text('Total Value: ${_products.fold<int>(0, (sum, p) => sum + ((p['price'] as int) * (p['stock'] as int)))} RWF'), // TODO: Replace with loc.totalValue if added to ARB
                      SizedBox(height: 16),
                      Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)), // TODO: Replace with loc.categories if added to ARB
                      ..._categoryKeys.map((key) => Text('• ${localizedCategory(context, key)}: ${_products.where((p) => p['category'] == key).length} items')), // TODO: Replace 'items' with loc.items if added to ARB
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              try {
                final lang = Localizations.localeOf(context).languageCode;
                await _printService.printInventoryReport(_products, lang);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error printing report: $e')),
                );
              }
            },
            tooltip: Localizations.localeOf(context).languageCode == 'fr'
                ? 'Imprimer le rapport d\'inventaire'
                : 'Print inventory report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...', // TODO: Replace with loc.searchProducts if added to ARB
                prefixIcon: Icon(Icons.search, color: mainColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Product Form (when adding/editing)
          if (_isAddingProduct)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mainColor),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingProductId != null ? AppLocalizations.of(context)!.editProduct : AppLocalizations.of(context)!.addNewProduct,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.productName,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterProductName;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.price,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.pleaseEnterPrice;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.stock,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.pleaseEnterStock;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categoryController.text.isEmpty ? null : _categoryController.text,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.category,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _categoryKeys.map((key) {
                        return DropdownMenuItem(value: key, child: Text(localizedCategory(context, key)));
                      }).toList(),
                      onChanged: (value) {
                        _categoryController.text = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseSelectCategory;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProduct,
                            style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                            child: Text(AppLocalizations.of(context)!.save, style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isAddingProduct = false;
                              });
                              _resetForm();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Products List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: mainColor))
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? AppLocalizations.of(context)!.noProductsYet : AppLocalizations.of(context)!.noProductsFound,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text(AppLocalizations.of(context)!.addFirstProduct),
                            style: ElevatedButton.styleFrom(backgroundColor: mainColor),
                            onPressed: _addProduct,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                                         itemBuilder: (context, index) {
                       final product = _filteredProducts[index];
                       final isLowStock = (product['stock'] as int) <= (product['minStock'] as int);
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLowStock ? Colors.red : mainColor,
                            child: Icon(
                              isLowStock ? Icons.warning : Icons.inventory,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            product['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${product['price']} RWF • Stock: ${product['stock']}'), // TODO: Replace 'Stock' with loc.stock if added to ARB
                              Text(
                                // Show localized category
                                localizedCategory(context, product['category']),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (isLowStock)
                                Text(
                                  'LOW STOCK!', // TODO: Replace with loc.lowStockWarning if added to ARB
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text(AppLocalizations.of(context)!.edit),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () => _editProduct(index),
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(Icons.add),
                                  title: Text(AppLocalizations.of(context)!.updateStock),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final stockController = TextEditingController(text: product['stock'].toString());
                                      return AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.updateStock),
                                        content: TextField(
                                          controller: stockController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.newStockLevel),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(AppLocalizations.of(context)!.cancel),
                                          ),
                                                                                     ElevatedButton(
                                             onPressed: () {
                                               final newStock = int.tryParse(stockController.text);
                                               if (newStock != null) {
                                                 _updateStock(index, newStock);
                                               }
                                               Navigator.pop(context);
                                             },
                                            child: Text(AppLocalizations.of(context)!.update),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () => _deleteProduct(index),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: mainColor,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
} 