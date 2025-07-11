import 'package:flutter/material.dart';
import '../models/fruit.dart';
import '../services/fruit_service.dart';
import '../widgets/fruit_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FruitService _fruitService = FruitService();
  List<Fruit> _searchResults = [];
  String _selectedCategory = 'All';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _searchResults = _fruitService.allFruits;
  }

  void _performSearch(String query) {
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _searchResults = _fruitService.allFruits;
      } else {
        List<Fruit> results = _fruitService.searchFruits(query);
        if (_selectedCategory != 'All') {
          results = results.where((fruit) => fruit.category == _selectedCategory).toList();
        }
        _searchResults = results;
      }
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Premium Feature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search is a premium feature. Upgrade to access premium search.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Icon(Icons.lock, color: Colors.grey, size: 32),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isPremium = true;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are now a premium user! Enjoy searching.')),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _searchResults = _fruitService.searchFruits(_searchController.text);
      } else {
        List<Fruit> results = _fruitService.getFruitsByCategory(category);
        if (_searchController.text.isNotEmpty) {
          results = results.where((fruit) => 
            fruit.name.toLowerCase().contains(_searchController.text.toLowerCase())
          ).toList();
        }
        _searchResults = results;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._fruitService.categories];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search Fruits',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search for fruits...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => _filterByCategory(category),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Search Results
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No fruits found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_searchResults.length} fruits found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final fruit = _searchResults[index];
                              return FruitCard(
                                fruit: fruit,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/product-detail',
                                    arguments: {
                                      'name': fruit.name,
                                      'price': fruit.price,
                                      'seller': fruit.seller,
                                      'image': fruit.icon,
                                      'color': fruit.color,
                                      'description': fruit.description,
                                      'rating': fruit.rating,
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

