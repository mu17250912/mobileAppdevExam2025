import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  String _searchQuery = '';
  bool _loading = true;

  // Mock local service data
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'name': 'Plumber Pro',
      'description': 'Expert plumbing services for your home.',
      'lat': 37.7749,
      'lng': -122.4194,
    },
    {
      'id': '2',
      'name': 'Electrician Express',
      'description': 'Certified electricians for all needs.',
      'lat': 37.7849,
      'lng': -122.4094,
    },
    {
      'id': '3',
      'name': 'Clean & Shine',
      'description': 'Professional cleaning services.',
      'lat': 37.7649,
      'lng': -122.4294,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loading = false;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _currentPosition = position;
    });
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((data) {
      return data['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Set<Marker> get _serviceMarkers {
    return _filteredServices.map((data) {
      return Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(title: data['name']),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _currentPosition == null
                    ? const Center(child: Text('Getting location...'))
                    : Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              zoom: 13,
                            ),
                            markers: _serviceMarkers,
                            myLocationEnabled: true,
                            onMapCreated: (controller) {},
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              height: 160,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filteredServices.length,
                                itemBuilder: (context, index) {
                                  final data = _filteredServices[index];
                                  return Card(
                                    margin: const EdgeInsets.all(8),
                                    child: Container(
                                      width: 220,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 6),
                                          Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/booking', arguments: data);
                                            },
                                            child: const Text('Book Now'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
