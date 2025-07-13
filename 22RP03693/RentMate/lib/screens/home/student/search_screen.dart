import 'package:flutter/material.dart';
import '../../../models/property.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/theme.dart';
import 'property_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static Property getMockProperty(int index) {
    // Use a set of visually appealing sample images
    final sampleImages = [
      'https://images.pexels.com/photos/1743227/pexels-photo-1743227.jpeg',
      'https://images.pexels.com/photos/24245783/pexels-photo-24245783.jpeg',
      'https://images.pexels.com/photos/325259/pexels-photo-325259.jpeg',
      'https://images.pexels.com/photos/1599791/pexels-photo-1599791.jpeg',
      'https://images.pexels.com/photos/1571462/pexels-photo-1571462.jpeg',
    ];
    return Property(
      id: 'property_$index',
      landlordId: 'landlord_$index',
      title: 'Student Apartment 	${index + 1}',
      description: 'Modern apartment perfect for students with all amenities included.',
      monthlyRent: 50000.0 + (index * 5000),
      propertyType: PropertyType.apartment,
      bedrooms: 1 + (index % 3),
      bathrooms: 1,
      squareFootage: 500 + (index * 50),
      address: '${100 + index} University Ave, Campus Town',
      latitude: 40.7128,
      longitude: -74.0060,
      images: [sampleImages[index % sampleImages.length]],
      amenities: ['WiFi', 'Kitchen', 'Laundry', 'Parking'],
      landlordName: 'Landlord ${index + 1}',
      landlordPhone: '+123456789${index}',
      createdAt: DateTime.now(),
    );
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  
  double _minPrice = 0;
  double _maxPrice = 2000;
  int _selectedBedrooms = 0;
  PropertyType _selectedPropertyType = PropertyType.apartment;
  bool _showFilters = false;

  late List<Property> _allProperties;
  List<Property> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _allProperties = List.generate(10, (index) => SearchScreen.getMockProperty(index));
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _allProperties.where((property) {
        final matchesKeyword = _searchController.text.isEmpty ||
            property.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            property.description.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesLocation = _locationController.text.isEmpty ||
            property.address.toLowerCase().contains(_locationController.text.toLowerCase());
        final matchesType = property.propertyType == _selectedPropertyType;
        final matchesPrice = property.monthlyRent >= _minPrice && property.monthlyRent <= _maxPrice;
        final matchesBedrooms = _selectedBedrooms == 0 || property.bedrooms >= _selectedBedrooms;
        return matchesKeyword && matchesLocation && matchesType && matchesPrice && matchesBedrooms;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Properties'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Search properties',
                    hint: 'Enter keywords, amenities...',
                    prefixIcon: Icons.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    // TODO: Use current location
                  },
                  icon: const Icon(Icons.my_location),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Filters
          if (_showFilters) _buildFilters(),
          // Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProperties.length,
              itemBuilder: (context, index) {
                final property = _filteredProperties[index];
                return PropertyCard(
                  property: property,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailsScreen(property: property),
                      ),
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Location
          CustomTextField(
            controller: _locationController,
            label: 'Location',
            hint: 'Enter city, university, or address',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          // Property Type
          Text(
            'Property Type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PropertyType.values.map((type) {
              final isSelected = _selectedPropertyType == type;
              return FilterChip(
                label: Text(type.toString().split('.').last.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedPropertyType = type;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Price Range
          Text(
            'Price Range: \$${_minPrice.toInt()} - \$${_maxPrice.toInt()}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 2000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_minPrice.toInt()}',
              '\$${_maxPrice.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 16),
          // Bedrooms
          Text(
            'Bedrooms',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Any'),
                selected: _selectedBedrooms == 0,
                onSelected: (selected) {
                  setState(() {
                    _selectedBedrooms = 0;
                  });
                },
              ),
              ...List.generate(4, (index) {
                final bedrooms = index + 1;
                return FilterChip(
                  label: Text('$bedrooms+'),
                  selected: _selectedBedrooms == bedrooms,
                  onSelected: (selected) {
                    setState(() {
                      _selectedBedrooms = bedrooms;
                    });
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
} 