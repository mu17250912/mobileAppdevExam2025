import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'session_manager.dart';
import 'user_dashboard_screen.dart';
import 'services/firebase_service.dart'; // Add Firebase service import
import 'package:video_player/video_player.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  String searchQuery = '';
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> categories = [
    'All',
    'Nitrogen',
    'Phosphate',
    'Potassium',
    'Balanced',
    'Organic',
    'Micronutrients'
  ];

  @override
  void initState() {
    super.initState();
    final userId = SessionManager().userId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return;
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (selectedCategory == 'All') {
      return products;
    }
    return products.where((product) => product['category'] == selectedCategory).toList();
  }

  IconData getProductIcon(String category) {
    switch (category) {
      case 'Nitrogen':
        return Icons.grass;
      case 'Phosphate':
        return Icons.eco;
      case 'Potassium':
        return Icons.local_florist;
      case 'Balanced':
        return Icons.balance;
      case 'Organic':
        return Icons.eco;
      case 'Micronutrients':
        return Icons.science;
      default:
        return Icons.agriculture;
    }
  }

  Color getProductColor(String category) {
    switch (category) {
      case 'Nitrogen':
        return Colors.green;
      case 'Phosphate':
        return Colors.blue;
      case 'Potassium':
        return Colors.orange;
      case 'Balanced':
        return Colors.purple;
      case 'Organic':
        return Colors.brown;
      case 'Micronutrients':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void addToCart(Map<String, dynamic> product) async {
    final userId = SessionManager().userId;
    if (userId == null) return;
    
    try {
      final currentCart = await _firebaseService.getCartItems(userId);
      currentCart.add({
        'productId': product['id'],
        'name': product['name'],
        'price': product['price'],
        'category': product['category'],
        'quantity': 1,
      });
      
      await _firebaseService.updateCart(userId, currentCart);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} added to cart!'), 
          backgroundColor: Colors.green
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizers', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Category filter
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF1976D2),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Products grid from Firestore
          Expanded(
            child: StreamBuilder(
              stream: _firebaseService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found in this category',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                final allProducts = snapshot.data!.docs.map((doc) => {
                  'id': doc.id, 
                  ...doc.data() as Map<String, dynamic>
                }).toList();
                final visibleProducts = allProducts.where((product) {
                  final matchesCategory = selectedCategory == 'All' || product['category'] == selectedCategory;
                  final matchesSearch = searchQuery.isEmpty || 
                      (product['name']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
                  return matchesCategory && matchesSearch;
                }).toList();
                if (visibleProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found in this category',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: visibleProducts.length,
                  itemBuilder: (context, index) {
                    final product = visibleProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      onAddToCart: () => addToCart(product),
                      getProductIcon: getProductIcon,
                      getProductColor: getProductColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final IconData Function(String) getProductIcon;
  final Color Function(String) getProductColor;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    required this.getProductIcon,
    required this.getProductColor,
  });

  @override
  Widget build(BuildContext context) {
    final category = product['category'] ?? 'Other';
    final icon = getProductIcon(category);
    final color = getProductColor(category);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product icon
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              // Product name
              Text(
                product['name'] ?? 'Unknown Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Price
              Text(
                'RWF ${(product['price'] ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 4),
              // Add to Cart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add_shopping_cart),
                  label: Text('Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onAddToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 