import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/property.dart';
import '../utils/string_extensions.dart';

class SearchSuggestions extends StatefulWidget {
  final String query;
  final List<Property> properties;
  final Function(String) onSuggestionSelected;
  final VoidCallback? onClear;

  const SearchSuggestions({
    super.key,
    required this.query,
    required this.properties,
    required this.onSuggestionSelected,
    this.onClear,
  });

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  @override
  void didUpdateWidget(SearchSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _generateSuggestions();
    }
  }

  void _generateSuggestions() {
    if (widget.query.isEmpty) {
      setState(() {
        _suggestions = _getPopularSearches();
      });
      return;
    }

    final query = widget.query.toLowerCase();
    final Map<String, Map<String, dynamic>> suggestions = {};

    // Property type suggestions
    final propertyTypes = widget.properties.map((p) => p.propertyType).toSet();
    for (final type in propertyTypes) {
      if (type.toLowerCase().contains(query)) {
        suggestions['type_$type'] = {
          'type': 'property_type',
          'text': type.capitalize(),
          'icon': Icons.home,
          'subtitle': 'Property Type',
        };
      }
    }

    // Location suggestions
    final locations = widget.properties.map((p) => p.address).toSet();
    for (final location in locations) {
      if (location.toLowerCase().contains(query)) {
        final parts = location.split(',');
        if (parts.isNotEmpty) {
          final city = parts.last.trim();
          suggestions['location_$city'] = {
            'type': 'location',
            'text': city,
            'icon': Icons.location_on,
            'subtitle': 'Location',
          };
        }
      }
    }

    // Amenity suggestions
    final amenities = <String>{};
    for (final property in widget.properties) {
      amenities.addAll(property.amenities);
    }
    for (final amenity in amenities) {
      if (amenity.toLowerCase().contains(query)) {
        suggestions['amenity_$amenity'] = {
          'type': 'amenity',
          'text': amenity,
          'icon': Icons.check_circle,
          'subtitle': 'Amenity',
        };
      }
    }

    // Price range suggestions
    if (query.contains('price') || query.contains('\$')) {
      final prices = widget.properties.map((p) => p.price).toList();
      if (prices.isNotEmpty) {
        final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
        suggestions['price_avg'] = {
          'type': 'price',
          'text': 'Around \$${avgPrice.round()}',
          'icon': Icons.attach_money,
          'subtitle': 'Average Price',
        };
      }
    }

    // Bedroom suggestions
    if (query.contains('bedroom') || query.contains('room')) {
      for (int i = 1; i <= 5; i++) {
        suggestions['bedroom_$i'] = {
          'type': 'bedrooms',
          'text': '$i Bedroom${i > 1 ? 's' : ''}',
          'icon': Icons.bed,
          'subtitle': 'Bedrooms',
        };
      }
    }

    setState(() {
      _suggestions = suggestions.values.toList();
    });
  }

  List<Map<String, dynamic>> _getPopularSearches() {
    return [
      {
        'type': 'popular',
        'text': 'Houses for Sale',
        'icon': Icons.home,
        'subtitle': 'Popular Search',
      },
      {
        'type': 'popular',
        'text': 'Apartments for Rent',
        'icon': Icons.apartment,
        'subtitle': 'Popular Search',
      },
      {
        'type': 'popular',
        'text': 'Properties with Pool',
        'icon': Icons.pool,
        'subtitle': 'Popular Search',
      },
      {
        'type': 'popular',
        'text': 'Properties with Parking',
        'icon': Icons.local_parking,
        'subtitle': 'Popular Search',
      },
      {
        'type': 'popular',
        'text': 'Under \$500,000',
        'icon': Icons.attach_money,
        'subtitle': 'Popular Search',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          if (widget.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Suggestions for "${widget.query}"',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (widget.onClear != null)
                    TextButton(
                      onPressed: widget.onClear,
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          
          // Suggestions list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                leading: Icon(
                  suggestion['icon'],
                  color: AppColors.primary,
                  size: 20,
                ),
                title: Text(
                  suggestion['text'],
                  style: AppTextStyles.body2,
                ),
                subtitle: Text(
                  suggestion['subtitle'],
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                onTap: () {
                  widget.onSuggestionSelected(suggestion['text']);
                },
              );
            },
          ),
        ],
      ),
    );
  }
} 