import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../models/property.dart';

class MapSearchWidget extends StatefulWidget {
  final List<Property> properties;
  final Function(Property) onPropertySelected;
  final Function(LatLng, double) onLocationSelected;

  const MapSearchWidget({
    super.key,
    required this.properties,
    required this.onPropertySelected,
    required this.onLocationSelected,
  });

  @override
  State<MapSearchWidget> createState() => _MapSearchWidgetState();
}

class _MapSearchWidgetState extends State<MapSearchWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  double _radius = 5000; // 5km default radius
  LatLng? _selectedLocation;
  bool _showRadius = false;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(MapSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.properties != widget.properties) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers = widget.properties.map((property) {
      return Marker(
        markerId: MarkerId(property.id),
        position: LatLng(property.latitude, property.longitude),
        infoWindow: InfoWindow(
          title: property.title,
          snippet: '\$${property.price.toStringAsFixed(0)}',
          onTap: () => widget.onPropertySelected(property),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          property.listingType == 'sale' 
              ? BitmapDescriptor.hueRed 
              : BitmapDescriptor.hueBlue,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map Controls
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('My Location'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleRadius,
                  icon: const Icon(Icons.radio_button_checked),
                  label: Text(_showRadius ? 'Hide Radius' : 'Show Radius'),
                ),
              ),
            ],
          ),
        ),
        
        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.7128, -74.0060), // New York
              zoom: 12,
            ),
            markers: _markers,
            circles: _showRadius && _selectedLocation != null
                ? {
                    Circle(
                      circleId: const CircleId('search_radius'),
                      center: _selectedLocation!,
                      radius: _radius,
                      fillColor: AppColors.primary.withOpacity(0.2),
                      strokeColor: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  }
                : {},
            onTap: (latLng) {
              setState(() {
                _selectedLocation = latLng;
                _showRadius = true;
              });
              widget.onLocationSelected(latLng, _radius);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
        
        // Radius Slider
        if (_showRadius && _selectedLocation != null)
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                Text(
                  'Search Radius: ${(_radius / 1000).toStringAsFixed(1)} km',
                  style: AppTextStyles.body2,
                ),
                Slider(
                  value: _radius,
                  min: 1000,
                  max: 50000,
                  divisions: 49,
                  onChanged: (value) {
                    setState(() {
                      _radius = value;
                    });
                    widget.onLocationSelected(_selectedLocation!, _radius);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _getCurrentLocation() async {
    // TODO: Implement current location functionality
    // This would require location permissions and geolocator package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location feature coming soon!')),
    );
  }

  void _toggleRadius() {
    setState(() {
      _showRadius = !_showRadius;
      if (!_showRadius) {
        _selectedLocation = null;
      }
    });
  }
} 