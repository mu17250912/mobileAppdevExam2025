import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'models/product_model.dart';
import 'services/cart_service.dart';
import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'widgets/loading_widget.dart';
import 'widgets/error_widget.dart';
import 'product_detail_screen.dart';
import 'payment_screen.dart';
import 'dart:async';

class FertilizerRecommendationScreen extends StatefulWidget {
  final String crop;
  final String week;
  final String area;

  const FertilizerRecommendationScreen({
    super.key,
    required this.crop,
    required this.week,
    required this.area,
  });

  @override
  State<FertilizerRecommendationScreen> createState() => _FertilizerRecommendationScreenState();
}

class _FertilizerRecommendationScreenState extends State<FertilizerRecommendationScreen> {
  // --- BEGIN: All Crops/Weeks Recommendation System ---
  final Map<String, Map<String, Map<String, String>>> recommendations = {
    'Maize': {
      'Week 1-2': {
        'name': 'DAP',
        'details': 'Provides essential phosphorus for early root development in maize.',
        'imageUrl': 'https://i.imgur.com/SXML4vj.png',
      },
      'Week 3-4': {
        'name': 'DAP',
        'details': 'Continue with DAP for strong root establishment.',
        'imageUrl': 'https://i.imgur.com/SXML4vj.png',
      },
      'Week 5-6': {
        'name': 'Urea',
        'details': 'Switch to Urea for vegetative growth.',
        'imageUrl': 'https://i.imgur.com/bZ0jYfQ.png',
      },
      'Flowering Stage': {
        'name': 'NPK 17-17-17',
        'details': 'Balanced nutrients for flowering and grain filling.',
        'imageUrl': 'https://i.imgur.com/maize_flower.png',
      },
      'default': {
        'name': 'Urea',
        'details': 'General nitrogen fertilizer for maize.',
        'imageUrl': 'https://i.imgur.com/bZ0jYfQ.png',
      }
    },
    'Potatoes': {
      'Week 1-2': {
        'name': 'NPK 15-15-15',
        'details': 'Balanced fertilizer for early potato growth.',
        'imageUrl': 'https://i.imgur.com/J5CoU3p.png',
      },
      'Week 3-4': {
        'name': 'NPK 15-15-15',
        'details': 'Continue with NPK for tuber initiation.',
        'imageUrl': 'https://i.imgur.com/J5CoU3p.png',
      },
      'Week 5-6': {
        'name': 'NPK 12-24-12',
        'details': 'Promotes tuber bulking and quality.',
        'imageUrl': 'https://i.imgur.com/potato_bulking.png',
      },
      'Flowering Stage': {
        'name': 'NPK 12-24-12',
        'details': 'Supports flowering and tuber development.',
        'imageUrl': 'https://i.imgur.com/potato_flower.png',
      },
      'default': {
        'name': 'NPK 15-15-15',
        'details': 'Balanced fertilizer for potatoes.',
        'imageUrl': 'https://i.imgur.com/J5CoU3p.png',
      }
    },
    'Beans': {
      'Week 1-2': {
        'name': 'NPK 20-20-0',
        'details': 'Ideal for beans during vegetative growth.',
        'imageUrl': 'https://i.imgur.com/beans.png',
      },
      'Week 3-4': {
        'name': 'NPK 20-20-0',
        'details': 'Continue with NPK for strong stems.',
        'imageUrl': 'https://i.imgur.com/beans.png',
      },
      'Week 5-6': {
        'name': 'NPK 10-30-10',
        'details': 'Promotes pod formation.',
        'imageUrl': 'https://i.imgur.com/beans_pod.png',
      },
      'Flowering Stage': {
        'name': 'NPK 10-30-10',
        'details': 'Supports flowering and pod set.',
        'imageUrl': 'https://i.imgur.com/beans_flower.png',
      },
      'default': {
        'name': 'NPK 20-20-0',
        'details': 'General fertilizer for beans.',
        'imageUrl': 'https://i.imgur.com/beans.png',
      }
    },
    'Tomatoes': {
      'Week 1-2': {
        'name': 'NPK 12-24-12',
        'details': 'Promotes root and early shoot growth.',
        'imageUrl': 'https://i.imgur.com/tomatoes.png',
      },
      'Week 3-4': {
        'name': 'NPK 12-24-12',
        'details': 'Continue with NPK for vegetative growth.',
        'imageUrl': 'https://i.imgur.com/tomatoes.png',
      },
      'Week 5-6': {
        'name': 'NPK 15-15-30',
        'details': 'Boosts fruit set and development.',
        'imageUrl': 'https://i.imgur.com/tomato_fruit.png',
      },
      'Flowering Stage': {
        'name': 'NPK 15-15-30',
        'details': 'Supports flowering and fruiting.',
        'imageUrl': 'https://i.imgur.com/tomato_flower.png',
      },
      'default': {
        'name': 'NPK 12-24-12',
        'details': 'General fertilizer for tomatoes.',
        'imageUrl': 'https://i.imgur.com/tomatoes.png',
      }
    }
  };

  final Map<String, String> globalDefault = {
    'name': 'Urea',
    'details': 'A good general-purpose nitrogen fertilizer for vegetative growth.',
    'imageUrl': 'https://i.imgur.com/bZ0jYfQ.png',
  };
  // --- END: All Crops/Weeks Recommendation System ---
  late Future<Product?> _productFuture;
  bool _isLoading = true;
  String? _errorMessage;
  Product? _product;
  late DateTime _loadStart;
  Map<String, String>? _dynamicRecommendation;

  @override
  void initState() {
    super.initState();
    _loadStart = DateTime.now();
    _productFuture = _fetchRecommendation();
    AnalyticsService.trackFeatureUsage(
      feature: 'fertilizer_recommendation_view',
      userRole: 'farmer',
      additionalData: 'crop=${widget.crop},week=${widget.week},area=${widget.area}',
    );
  }

  Future<Map<String, String>?> _fetchDynamicRecommendation() async {
    try {
      final snap = await FirebaseFirestore.instance
        .collection('fertilizer_recommendations')
        .where('crop', isEqualTo: widget.crop)
        .where('week', isEqualTo: widget.week)
        .limit(1)
        .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        return {
          'name': data['name'] ?? '',
          'details': data['details'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }
    } catch (e) {
      // Ignore and fallback
    }
    return null;
  }

  Map<String, String>? _getRecommendation() {
    // Only use dynamic (admin) recommendation, do not fall back to static map
    if (_dynamicRecommendation != null) {
      return _dynamicRecommendation;
    }
    return null;
  }

  Future<Product?> _fetchRecommendation() async {
    // Only use dynamic (dealer-managed) recommendation
    _dynamicRecommendation = await _fetchDynamicRecommendation();
    final rec = _getRecommendation();
    if (rec == null || rec['name'] == null || rec['name']!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No recommendation found for your selection.';
      });
      return null;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: rec['name'])
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final product = Product.fromMap(doc.data(), doc.id);
        setState(() {
          _product = product;
          _isLoading = false;
        });
        final loadTime = DateTime.now().difference(_loadStart).inMilliseconds;
        PerformanceService.trackScreenLoad('fertilizer_recommendation_screen', loadTimeMs: loadTime);
        return product;
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Recommended fertilizer not found in marketplace.';
        });
        return null;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching recommendation: $e';
      });
      return null;
    }
  }

  void _addToCartAndPay(Product product) {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.addItem(product.toMap());
    AnalyticsService.trackAddToCart(
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: 1,
      buyerRole: 'farmer',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: product.price,
          items: [product.toMap()..['quantity'] = 1],
        ),
      ),
    );
  }

  void _goToProductDetail(Product product) {
    AnalyticsService.trackProductView(
      productId: product.id,
      productName: product.name,
      dealer: product.dealer,
      viewerRole: 'farmer',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = _getRecommendation();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendation'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return ShimmerLoading(
              isLoading: true,
              child: _RecommendationCardSkeleton(),
            );
          }
          if (_errorMessage != null) {
            return CustomErrorWidget(
              message: _errorMessage!,
              title: 'No Recommendation',
              icon: Icons.science_outlined,
              color: Colors.orange,
              onRetry: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                  _productFuture = _fetchRecommendation();
                });
              },
            );
          }
          if (_product == null || rec == null) {
            return EmptyStateWidget(
              message: _errorMessage ?? 'No matching fertilizer found for your selection.',
              title: 'Not Available',
              icon: Icons.science_outlined,
            );
          }
          // --- BEGIN: Always-visible Full Overview ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        rec['imageUrl'] ?? '',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          width: 100,
                          height: 100,
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crop: ${widget.crop}', style: const TextStyle(fontSize: 16)),
                          Text('Week: ${widget.week}', style: const TextStyle(fontSize: 16)),
                          Text('Area: ${widget.area}', style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Fertilizer: ${rec['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(rec['details'] ?? '', style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_product != null) ...[
                  Text('Marketplace Product Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Name: ${_product!.name}', style: const TextStyle(fontSize: 16)),
                  Text('Description: ${_product!.description}', style: const TextStyle(fontSize: 15)),
                  Text('Category: ${_product!.category}', style: const TextStyle(fontSize: 15)),
                  Text('Price: RWF ${_product!.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15)),
                  Text('Stock: ${_product!.stock ?? 'N/A'}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 24),
                Text('Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _addToCartAndPay(_product!),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Add & Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _goToProductDetail(_product!),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          // --- END: Always-visible Full Overview ---
        },
      ),
    );
  }
}

class _RecommendationCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SkeletonLoader(height: 160, width: double.infinity, borderRadius: 16),
            const SizedBox(height: 20),
            SkeletonLoader(height: 28, width: 120, borderRadius: 8),
            const SizedBox(height: 8),
            SkeletonLoader(height: 16, width: 200, borderRadius: 8),
            const SizedBox(height: 16),
            SkeletonLoader(height: 14, width: 220, borderRadius: 8),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader(height: 28, width: 80, borderRadius: 16),
                const SizedBox(width: 12),
                SkeletonLoader(height: 28, width: 80, borderRadius: 16),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkeletonLoader(height: 48, width: 120, borderRadius: 12),
                SkeletonLoader(height: 48, width: 120, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 