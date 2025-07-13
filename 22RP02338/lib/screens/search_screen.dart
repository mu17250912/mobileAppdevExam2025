import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/search_suggestions.dart';
import '../utils/string_extensions.dart';
import '../widgets/map_search_widget.dart';
import 'property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  // Filter states
  String _selectedPropertyType = 'all';
  String _selectedListingType = 'all';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _bedroomRange = const RangeValues(0, 5);
  RangeValues _bathroomRange = const RangeValues(0, 5);
  RangeValues _areaRange = const RangeValues(0, 5000);
  List<String> _selectedAmenities = [];
  bool _showFeaturedOnly = false;
  String _sortBy = 'date';
  bool _sortDescending = true;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  
  // UI states
  bool _isLoading = false;
  bool _showSuggestions = false;
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    // Load properties and saved searches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = context.read<PropertyProvider>();
      propertyProvider.loadProperties();
      propertyProvider.loadSavedSearches();
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
            onPressed: _showSavedSearches,
            icon: const Icon(Icons.bookmark),
            tooltip: 'Saved Searches',
          ),
          IconButton(
            onPressed: _toggleMapView,
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            tooltip: _showMapView ? 'List View' : 'Map View',
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Advanced Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Search Suggestions
          if (_showSuggestions) _buildSearchSuggestions(),
          
          // Quick Filters
          _buildQuickFilters(),
          
          // Results Header
          _buildResultsHeader(),
          
          // Results
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                if (propertyProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredProperties = propertyProvider.filterProperties(
                  propertyType: _selectedPropertyType == 'all' ? null : _selectedPropertyType,
                  listingType: _selectedListingType == 'all' ? null : _selectedListingType,
                  minPrice: _priceRange.start,
                  maxPrice: _priceRange.end,
                  minBedrooms: _bedroomRange.start > 0 ? _bedroomRange.start.round() : null,
                  maxBedrooms: _bedroomRange.end < 5 ? _bedroomRange.end.round() : null,
                  minBathrooms: _bathroomRange.start > 0 ? _bathroomRange.start.round() : null,
                  minArea: _areaRange.start > 0 ? _areaRange.start : null,
                  maxArea: _areaRange.end < 5000 ? _areaRange.end : null,
                  amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
                  searchQuery: _searchController.text,
                  location: _locationController.text,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  isFeatured: _showFeaturedOnly ? true : null,
                  sortBy: _sortBy,
                  sortDescending: _sortDescending,
                );

                if (filteredProperties.isEmpty) {
                  return _buildEmptyState();
                }

                if (_showMapView) {
                  return MapSearchWidget(
                    properties: filteredProperties,
                    onPropertySelected: (property) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailScreen(property: property),
                        ),
                      );
                    },
                    onLocationSelected: (latLng, radius) {
                      // TODO: Implement location-based filtering
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Searching within ${(radius / 1000).toStringAsFixed(1)}km of selected location'),
                        ),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = filteredProperties[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < filteredProperties.length - 1 ? AppSizes.sm : 0,
                      ),
                      child: PropertyCard(
                        property: property,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(property: property),
                            ),
                          );
                        },
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
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
        children: [
          // Main search
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _showSuggestions = value.isNotEmpty;
              });
            },
            onTap: () {
              setState(() {
                _showSuggestions = _searchController.text.isNotEmpty;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search properties, amenities, or keywords...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showSuggestions = false;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
          ),
          // Location search
          TextField(
            controller: _locationController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Location, city, or neighborhood...',
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: _locationController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _locationController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        return SearchSuggestions(
          query: _searchController.text,
          properties: propertyProvider.properties,
          onSuggestionSelected: (suggestion) {
            setState(() {
              _searchController.text = suggestion;
              _showSuggestions = false;
            });
          },
          onClear: () {
            setState(() {
              _searchController.clear();
              _showSuggestions = false;
            });
          },
        );
      },
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Types',
            isSelected: _selectedPropertyType == 'all',
            onTap: () => setState(() => _selectedPropertyType = 'all'),
          ),
          const SizedBox(width: AppSizes.sm),
          _buildFilterChip(
            label: 'Houses',
            isSelected: _selectedPropertyType == 'house',
            onTap: () => setState(() => _selectedPropertyType = 'house'),
          ),
          const SizedBox(width: AppSizes.sm),
          _buildFilterChip(
            label: 'Apartments',
            isSelected: _selectedPropertyType == 'apartment',
            onTap: () => setState(() => _selectedPropertyType = 'apartment'),
          ),
          const SizedBox(width: AppSizes.sm),
          _buildFilterChip(
            label: 'For Sale',
            isSelected: _selectedListingType == 'sale',
            onTap: () => setState(() => _selectedListingType = 'sale'),
          ),
          const SizedBox(width: AppSizes.sm),
          _buildFilterChip(
            label: 'For Rent',
            isSelected: _selectedListingType == 'rent',
            onTap: () => setState(() => _selectedListingType = 'rent'),
          ),
          const SizedBox(width: AppSizes.sm),
          _buildFilterChip(
            label: 'Featured',
            isSelected: _showFeaturedOnly,
            onTap: () => setState(() => _showFeaturedOnly = !_showFeaturedOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final filteredProperties = propertyProvider.filterProperties(
          propertyType: _selectedPropertyType == 'all' ? null : _selectedPropertyType,
          listingType: _selectedListingType == 'all' ? null : _selectedListingType,
          minPrice: _priceRange.start,
          maxPrice: _priceRange.end,
          minBedrooms: _bedroomRange.start > 0 ? _bedroomRange.start.round() : null,
          maxBedrooms: _bedroomRange.end < 5 ? _bedroomRange.end.round() : null,
          minBathrooms: _bathroomRange.start > 0 ? _bathroomRange.start.round() : null,
          minArea: _areaRange.start > 0 ? _areaRange.start : null,
          maxArea: _areaRange.end < 5000 ? _areaRange.end : null,
          amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
          searchQuery: _searchController.text,
          location: _locationController.text,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          isFeatured: _showFeaturedOnly ? true : null,
          sortBy: _sortBy,
          sortDescending: _sortDescending,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredProperties.length} properties found',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _saveCurrentSearch,
                    icon: const Icon(Icons.bookmark_add),
                    tooltip: 'Save Search',
                  ),
                  IconButton(
                    onPressed: _shareSearch,
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Search',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textTertiary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No properties found',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Try adjusting your search criteria',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ElevatedButton(
            onPressed: _resetFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property Type
                          Text('Property Type', style: AppTextStyles.heading5),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: AppSizes.sm,
                            children: [
                              'all', 'house', 'apartment', 'land', 'commercial'
                            ].map((type) {
                              final isSelected = _selectedPropertyType == type;
                              return ChoiceChip(
                                label: Text(type == 'all' ? 'All' : type.capitalize()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedPropertyType = type);
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Listing Type
                          Text('Listing Type', style: AppTextStyles.heading5),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: AppSizes.sm,
                            children: [
                              'all', 'sale', 'rent'
                            ].map((type) {
                              final isSelected = _selectedListingType == type;
                              return ChoiceChip(
                                label: Text(type == 'all' ? 'All' : type == 'sale' ? 'For Sale' : 'For Rent'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedListingType = type);
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Price Range
                          Text('Price Range', style: AppTextStyles.heading5),
                          const SizedBox(height: AppSizes.sm),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000000,
                            divisions: 100,
                            labels: RangeLabels(
                              '\$${_priceRange.start.round()}',
                              '\$${_priceRange.end.round()}',
                            ),
                            onChanged: (values) {
                              setState(() => _priceRange = values);
                            },
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Bedrooms & Bathrooms
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bedrooms', style: AppTextStyles.heading5),
                                    const SizedBox(height: AppSizes.sm),
                                    DropdownButtonFormField<int>(
                                      value: _bedroomRange.start.round(),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                                      ),
                                      items: [
                                        const DropdownMenuItem(value: 0, child: Text('Any')),
                                        const DropdownMenuItem(value: 1, child: Text('1+')),
                                        const DropdownMenuItem(value: 2, child: Text('2+')),
                                        const DropdownMenuItem(value: 3, child: Text('3+')),
                                        const DropdownMenuItem(value: 4, child: Text('4+')),
                                        const DropdownMenuItem(value: 5, child: Text('5+')),
                                      ],
                                      onChanged: (value) {
                                        setState(() => _bedroomRange = RangeValues(value!.toDouble(), _bedroomRange.end));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bathrooms', style: AppTextStyles.heading5),
                                    const SizedBox(height: AppSizes.sm),
                                    DropdownButtonFormField<int>(
                                      value: _bathroomRange.start.round(),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                                      ),
                                      items: [
                                        const DropdownMenuItem(value: 0, child: Text('Any')),
                                        const DropdownMenuItem(value: 1, child: Text('1+')),
                                        const DropdownMenuItem(value: 2, child: Text('2+')),
                                        const DropdownMenuItem(value: 3, child: Text('3+')),
                                        const DropdownMenuItem(value: 4, child: Text('4+')),
                                        const DropdownMenuItem(value: 5, child: Text('5+')),
                                      ],
                                      onChanged: (value) {
                                        setState(() => _bathroomRange = RangeValues(value!.toDouble(), _bathroomRange.end));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSizes.lg),

                          // Featured Only
                          SwitchListTile(
                            title: const Text('Featured Properties Only'),
                            value: _showFeaturedOnly,
                            onChanged: (value) {
                              setState(() => _showFeaturedOnly = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
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

  void _showSavedSearches() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSavedSearchesBottomSheet(),
    );
  }

  Widget _buildSavedSearchesBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Saved Searches',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                if (propertyProvider.isLoadingSearches) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (propertyProvider.savedSearches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'No saved searches',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Save your favorite searches for quick access',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  itemCount: propertyProvider.savedSearches.length,
                  itemBuilder: (context, index) {
                    final search = propertyProvider.savedSearches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: ListTile(
                        title: Text(search['name']),
                        subtitle: Text(
                          '${search['filters'].length} filters applied',
                          style: AppTextStyles.caption,
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteSavedSearch(search['id']),
                          icon: const Icon(Icons.delete),
                        ),
                        onTap: () => _loadSavedSearch(search['filters']),
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

  void _resetFilters() {
    setState(() {
      _selectedPropertyType = 'all';
      _selectedListingType = 'all';
      _priceRange = const RangeValues(0, 1000000);
      _bedroomRange = const RangeValues(0, 5);
      _bathroomRange = const RangeValues(0, 5);
      _areaRange = const RangeValues(0, 5000);
      _selectedAmenities.clear();
      _showFeaturedOnly = false;
      _sortBy = 'date';
      _sortDescending = true;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  void _saveCurrentSearch() async {
    final name = await _showSaveSearchDialog();
    if (name != null && name.isNotEmpty) {
      final filters = {
        'propertyType': _selectedPropertyType,
        'listingType': _selectedListingType,
        'minPrice': _priceRange.start,
        'maxPrice': _priceRange.end,
        'minBedrooms': _bedroomRange.start,
        'maxBedrooms': _bedroomRange.end,
        'minBathrooms': _bathroomRange.start,
        'minArea': _areaRange.start,
        'maxArea': _areaRange.end,
        'amenities': _selectedAmenities,
        'searchQuery': _searchController.text,
        'location': _locationController.text,
        'showFeaturedOnly': _showFeaturedOnly,
        'sortBy': _sortBy,
        'sortDescending': _sortDescending,
      };
      
      final success = await context.read<PropertyProvider>().saveSearch(name, filters);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search "$name" saved successfully')),
        );
      }
    }
  }

  Future<String?> _showSaveSearchDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Search'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Search Name',
            hintText: 'e.g., Downtown Apartments',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _loadSavedSearch(Map<String, dynamic> filters) {
    setState(() {
      _selectedPropertyType = filters['propertyType'] ?? 'all';
      _selectedListingType = filters['listingType'] ?? 'all';
      _priceRange = RangeValues(
        (filters['minPrice'] ?? 0).toDouble(),
        (filters['maxPrice'] ?? 1000000).toDouble(),
      );
      _bedroomRange = RangeValues(
        (filters['minBedrooms'] ?? 0).toDouble(),
        (filters['maxBedrooms'] ?? 5).toDouble(),
      );
      _bathroomRange = RangeValues(
        (filters['minBathrooms'] ?? 0).toDouble(),
        5.0,
      );
      _areaRange = RangeValues(
        (filters['minArea'] ?? 0).toDouble(),
        (filters['maxArea'] ?? 5000).toDouble(),
      );
      _selectedAmenities = List<String>.from(filters['amenities'] ?? []);
      _searchController.text = filters['searchQuery'] ?? '';
      _locationController.text = filters['location'] ?? '';
      _showFeaturedOnly = filters['showFeaturedOnly'] ?? false;
      _sortBy = filters['sortBy'] ?? 'date';
      _sortDescending = filters['sortDescending'] ?? true;
    });
    Navigator.pop(context);
  }

  void _deleteSavedSearch(String searchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: const Text('Are you sure you want to delete this saved search?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await context.read<PropertyProvider>().deleteSavedSearch(searchId);
    }
  }

  void _toggleMapView() {
    setState(() {
      _showMapView = !_showMapView;
    });
  }

  void _shareSearch() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
} 