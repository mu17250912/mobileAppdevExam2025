import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product_model.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'services/cart_service.dart';
import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'services/error_reporting_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'payment_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'All',
    'Fertilizers',
    'Seeds',
    'Tools',
    'Pesticides',
    'Equipment',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _trackScreenView();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _slideController.forward();
    });
  }

  Future<void> _trackScreenView() async {
    try {
      await AnalyticsService.trackScreenView('marketplace_screen');
      await PerformanceService.trackScreenLoad('marketplace_screen');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Marketplace',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showSearchDialog();
          },
        ),
        Consumer<CartService>(
          builder: (context, cart, child) => Badge(
            label: Text(
              cart.itemCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            isLabelVisible: cart.itemCount > 0,
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                HapticFeedback.lightImpact();
                _navigateToCart();
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: _buildCategoryFilter(),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF6F8FA),
            child: _buildProductList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedCategory = category;
                });
                AnalyticsService.trackEvent('category_filter', parameters: {
                  'category': category,
                  'timestamp': DateTime.now().toIso8601String(),
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF4CAF50),
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 1,
              pressElevation: 2,
              showCheckmark: false,
              side: isSelected
                  ? const BorderSide(color: Color(0xFF388E3C), width: 2)
                  : BorderSide(color: Colors.grey[300]!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
        stream: _selectedCategory == 'All'
            ? FirebaseFirestore.instance
                .collection('products')
                .where('stock', isGreaterThan: 0)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: _selectedCategory)
                .where('stock', isGreaterThan: 0)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 16),
                Text('Loading products...'),
              ],
            ),
            );
          }
        
          if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later.',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCategory == 'All'
                      ? 'Check back later for new products'
                      : 'No products in this category',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        // Filter by search query if any
        final filteredProducts = _searchQuery.isEmpty
            ? products
            : products.where((product) {
                final name = (product['name'] ?? '').toString().toLowerCase();
                final description = (product['description'] ?? '').toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || description.contains(query);
              }).toList();

        if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search terms',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
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
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(context, product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final imageUrl = (product['imageUrl'] ?? '').isNotEmpty
        ? product['imageUrl']
        : 'https://via.placeholder.com/300x300.png?text=No+Image';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          _addToCartAndPay(product);
        },
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 48, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'No name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222B45),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RWF ${product['price']?.toStringAsFixed(0) ?? '0'}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _addToCartAndPay(product);
                            },
                            color: const Color(0xFF4CAF50),
                            iconSize: 20,
                            tooltip: 'Add to cart & pay',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _filterProduct(Product product) {
    if (_selectedCategory != 'All' && product.category != _selectedCategory) {
      return false;
    }
    
    if (_searchQuery.isNotEmpty) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             product.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }
    
    return true;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter product name or description...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
        },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AnalyticsService.trackSearch(
                query: _searchQuery,
                category: _selectedCategory,
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    AnalyticsService.trackProductView(
      productId: product['id'],
      productName: product['name'],
      dealer: product['dealer'],
      viewerRole: 'farmer',
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: Product.fromMap(product, product['id'])),
      ),
    );
  }

  void _addToCartAndPay(Map<String, dynamic> product) {
    // Debug print to help diagnose add_to_cart_error
    print('Attempting to add to cart: $product');
    // Validate required fields
    final requiredFields = ['id', 'name', 'price'];
    for (final field in requiredFields) {
      if (product[field] == null || product[field].toString().isEmpty) {
        ErrorReportingService.reportError(
          errorType: 'add_to_cart_error',
          errorMessage: 'Product missing required field: $field',
          additionalData: product,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot add to cart: missing $field'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.addItem(product);
      if (!cartService.hasItem(product['id'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart.'), backgroundColor: Colors.red),
        );
        return;
      }
      AnalyticsService.trackAddToCart(
        productId: product['id'],
        productName: product['name'],
        price: product['price'],
        quantity: 1,
        buyerRole: 'farmer',
      );
      final items = [
        {
          ...product,
          'quantity': 1,
        }
      ];
      final totalAmount = (product['price'] is num ? product['price'] : 0.0) * 1.0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            totalAmount: totalAmount,
            items: items,
          ),
        ),
      );
    } catch (e) {
      ErrorReportingService.reportError(
        errorType: 'add_to_cart_error',
        errorMessage: 'Failed to add product to cart',
        error: e,
        additionalData: product,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 