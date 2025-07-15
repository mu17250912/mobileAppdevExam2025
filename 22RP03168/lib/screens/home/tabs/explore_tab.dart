import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';
import '../../product/product_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Shoes', 'Clothes', 'Accessories'];
  
  // Dummy product data
  final List<Product> products = [
    Product(
      id: '1',
      title: 'Nike Air Max',
      description: 'Comfortable running shoes with excellent cushioning',
      price: 89.99,
      originalPrice: 120.00,
      category: 'Shoes',
      condition: 'New',
      brand: 'Nike',
      size: '42',
      color: 'Black',
      sellerId: 'seller_1',
      sellerName: 'SportsStore',
      images: ['https://via.placeholder.com/300x300'],
      createdAt: DateTime.now(),
    ),
    Product(
      id: '2',
      title: 'Adidas Ultraboost',
      description: 'Premium running shoes with energy return technology',
      price: 129.99,
      originalPrice: 129.99,
      category: 'Shoes',
      condition: 'New',
      brand: 'Adidas',
      size: '41',
      color: 'White',
      sellerId: 'seller_2',
      sellerName: 'AthleticGear',
      images: ['https://via.placeholder.com/300x300'],
      createdAt: DateTime.now(),
    ),
    Product(
      id: '3',
      title: 'Denim Jacket',
      description: 'Classic denim jacket perfect for casual wear',
      price: 59.99,
      originalPrice: 79.99,
      category: 'Clothes',
      condition: 'Like New',
      brand: 'Levi\'s',
      size: 'M',
      color: 'Blue',
      sellerId: 'seller_3',
      sellerName: 'FashionHub',
      images: ['https://via.placeholder.com/300x300'],
      createdAt: DateTime.now(),
    ),
    Product(
      id: '4',
      title: 'Graphic T-Shirt',
      description: 'Comfortable cotton t-shirt with unique design',
      price: 19.99,
      originalPrice: 19.99,
      category: 'Clothes',
      condition: 'New',
      brand: 'UrbanStyle',
      size: 'L',
      color: 'Black',
      sellerId: 'seller_4',
      sellerName: 'StreetWear',
      images: ['https://via.placeholder.com/300x300'],
      createdAt: DateTime.now(),
    ),
  ];

  List<Product> get filteredProducts {
    if (_selectedCategory == 'All') {
      return products;
    }
    return products.where((product) => product.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for shoes, clothes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),
        
        // Category Filter
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.deepPurple.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Products Grid
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: {
                                'id': product.id,
                                'name': product.title,
                                'description': product.description,
                                'price': product.price,
                                'category': product.category,
                                'brand': product.brand,
                                'condition': product.condition,
                                'stock': 10,
                                'sellerId': product.sellerId,
                                'sellerName': product.sellerName,
                                'sellerRating': '4.8',
                                'sellerReviews': '156',
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
} 