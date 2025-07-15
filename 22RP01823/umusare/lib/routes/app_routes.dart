import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/catalog/home_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/delivery/delivery_tracking_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/index_screen.dart';
import '../widgets/auth_guard.dart';
import '../services/user_service.dart';
import '../widgets/main_bottom_nav_bar.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static final List<Map<String, dynamic>> categories = [
    {
      'label': 'All',
      'icon': Icons.all_inclusive,
      'color': Color(0xFF145A32),
      'desc': 'Browse all available fish',
    },
    {
      'label': 'Tilapia',
      'icon': Icons.set_meal,
      'color': Color(0xFF1ABC9C),
      'desc': 'Fresh and farmed tilapia',
    },
    {
      'label': 'Catfish',
      'icon': Icons.water,
      'color': Color(0xFF3498DB),
      'desc': 'Delicious catfish varieties',
    },
    {
      'label': 'Smoked',
      'icon': Icons.smoking_rooms,
      'color': Color(0xFF8D6E63),
      'desc': 'Smoked fish for rich flavor',
    },
    {
      'label': 'Dried',
      'icon': Icons.ac_unit,
      'color': Color(0xFFBCAAA4),
      'desc': 'Dried fish for preservation',
    },
    {
      'label': 'Nile Perch',
      'icon': Icons.emoji_food_beverage,
      'color': Color(0xFF5C6BC0),
      'desc': 'Lake-fresh Nile Perch',
    },
    {
      'label': 'Sardine',
      'icon': Icons.rice_bowl,
      'color': Color(0xFFF4D03F),
      'desc': 'Small, tasty sardines',
    },
    {
      'label': 'Other',
      'icon': Icons.more_horiz,
      'color': Color(0xFF616161),
      'desc': 'Other fish and seafood',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fish Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse by category to find your favorite fish.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  return GestureDetector(
                    onTap: () {
                      // TODO: Filter products by category or navigate
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected: ${cat['label']}'),
                          backgroundColor: cat['color'],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: cat['color'], width: 2),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: cat['color'].withOpacity(0.13),
                            radius: 28,
                            child: Icon(
                              cat['icon'],
                              color: cat['color'],
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cat['label'],
                            style: TextStyle(
                              color: cat['color'],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['desc'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
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
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 1),
    );
  }
}

class MessengerScreen extends StatelessWidget {
  const MessengerScreen({super.key});

  void _showNewChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: _NewChatForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145A32),
        elevation: 0,
        title: const Text(
          'Messenger',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xFF145A32), size: 54),
                    const SizedBox(height: 18),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF145A32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with a seller or support. Your messages will appear here.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment),
        label: const Text('New Chat'),
        onPressed: () => _showNewChatModal(context),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  void _showAddProductForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: _AddProductForm(),
      ),
    );
  }

  void _showEditProductForm(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: _EditProductForm(product: product),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ProductService().deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${product.name}" deleted.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A32),
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF145A32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Product',
            onPressed: () => _showAddProductForm(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Product>>(
          stream: ProductService().getProductsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF145A32)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading products', style: TextStyle(color: Colors.white)));
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return Center(child: Text('No products found.', style: TextStyle(color: Colors.white70)));
            }
            return GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, i) {
                final product = products[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF145A32), width: 1.2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              product.image,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF145A32),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.category,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.formattedPrice,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF145A32)),
                                  tooltip: 'Edit',
                                  onPressed: () => _showEditProductForm(context, product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDeleteProduct(context, product),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 1),
    );
  }
}

class _AddProductForm extends StatefulWidget {
  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _freshnessController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceUnitController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Tilapia', 'Catfish', 'Smoked', 'Dried', 'Nile Perch', 'Sardine', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _freshnessController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final product = Product(
        id: '',
        name: _nameController.text.trim(),
        image: _imageController.text.trim(),
        freshness: _freshnessController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        priceUnit: _priceUnitController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? 'Other',
      );
      await ProductService().addProduct(product);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Color(0xFF145A32),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF145A32))),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Image URL required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _freshnessController,
              decoration: const InputDecoration(labelText: 'Freshness (e.g. Fresh, Smoked, Dried)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Freshness required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Price required';
                      final value = double.tryParse(v.trim());
                      if (value == null || value <= 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _priceUnitController,
                    decoration: const InputDecoration(labelText: 'Unit (e.g. kg, piece)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Unit required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Category required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _EditProductForm extends StatefulWidget {
  final Product product;
  const _EditProductForm({required this.product});
  @override
  State<_EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<_EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  late TextEditingController _freshnessController;
  late TextEditingController _priceController;
  late TextEditingController _priceUnitController;
  late TextEditingController _descriptionController;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Tilapia', 'Catfish', 'Smoked', 'Dried', 'Nile Perch', 'Sardine', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _imageController = TextEditingController(text: widget.product.image);
    _freshnessController = TextEditingController(text: widget.product.freshness);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _priceUnitController = TextEditingController(text: widget.product.priceUnit);
    _descriptionController = TextEditingController(text: widget.product.description);
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _freshnessController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        image: _imageController.text.trim(),
        freshness: _freshnessController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        priceUnit: _priceUnitController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? 'Other',
      );
      await ProductService().updateProduct(updatedProduct);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Color(0xFF145A32),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF145A32))),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Image URL required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _freshnessController,
              decoration: const InputDecoration(labelText: 'Freshness (e.g. Fresh, Smoked, Dried)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Freshness required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Price required';
                      final value = double.tryParse(v.trim());
                      if (value == null || value <= 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _priceUnitController,
                    decoration: const InputDecoration(labelText: 'Unit (e.g. kg, piece)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Unit required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Category required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Product'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _NewChatForm extends StatefulWidget {
  @override
  State<_NewChatForm> createState() => _NewChatFormState();
}

class _NewChatFormState extends State<_NewChatForm> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat started! (feature coming soon)'),
          backgroundColor: Color(0xFF145A32),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Start a New Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF145A32))),
            const SizedBox(height: 18),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Type your message...'
              ),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Message required' : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Start Chat'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/', 
      builder: (context, state) {
        // Check if user is logged in and redirect accordingly
        if (UserService.isLoggedIn && !UserService.isSessionDestroyed) {
          // User is logged in, redirect to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/home');
            }
          });
        }
        return const IndexScreen();
      }
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/home', 
      builder: (context, state) => const SecureAuthGuard(child: HomeScreen())
    ),
    GoRoute(
      path: '/cart', 
      builder: (context, state) => const SecureAuthGuard(child: CartScreen())
    ),
    GoRoute(
      path: '/checkout', 
      builder: (context, state) => const SecureAuthGuard(child: CheckoutScreen())
    ),
    GoRoute(
      path: '/orders', 
      builder: (context, state) => const SecureAuthGuard(child: OrdersScreen())
    ),
    GoRoute(
      path: '/delivery', 
      builder: (context, state) => const SecureAuthGuard(child: DeliveryTrackingScreen())
    ),
    GoRoute(
      path: '/profile', 
      builder: (context, state) => const SecureAuthGuard(child: ProfileScreen())
    ),
    GoRoute(
      path: '/settings', 
      builder: (context, state) => const SecureAuthGuard(child: SettingsScreen())
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const SecureAuthGuard(child: CategoriesScreen()),
    ),
    GoRoute(
      path: '/messenger',
      builder: (context, state) => const SecureAuthGuard(child: MessengerScreen()),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const SecureAuthGuard(child: ProductsScreen()),
    ),
  ],
); 