import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookings_screen.dart';
import 'account_screen.dart';
import 'notification_screen.dart';
import 'trip_detail_screen.dart';
import 'theme/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchSuggestions = [
    'Kruger',
    'Serengeti',
    'Grand Canyon',
    'Masai Mara',
    'Fiordland',
    'Jim Corbett',
    'Volcanoes',
    'Zhangjiajie',
    'Africa',
    'USA',
    'India',
    'China',
    'Kenya',
    'Tanzania',
    'South Africa',
    'Rwanda',
    'New Zealand',
  ];

  @override
  void initState() {
    super.initState();
    _initFCM();
    _populateSampleParksIfEmpty();
    FirebaseMessaging.instance.getToken().then((token) {
      print('FCM Token: $token');
    });
  }

  Future<void> _populateSampleParksIfEmpty() async {
    try {
      final parksSnapshot = await FirebaseFirestore.instance.collection('parks').limit(1).get();
      if (parksSnapshot.docs.isEmpty) {
        // Database is empty, add sample parks
        final sampleParks = [
          {
            'name': 'Kruger National Park',
            'description': 'One of Africa\'s largest game reserves, home to the Big Five and diverse wildlife.',
            'image': 'assets/kruger.png',
            'location': 'South Africa',
            'price': '150',
          },
          {
            'name': 'Jim Corbett National Park',
            'description': 'India\'s oldest national park, famous for Bengal tigers and rich biodiversity.',
            'image': 'assets/JimCorbett.png',
            'location': 'India',
            'price': '120',
          },
          {
            'name': 'Volcanoes National Park',
            'description': 'Home to endangered mountain gorillas and stunning volcanic landscapes.',
            'image': 'assets/volcanoes.png',
            'location': 'Rwanda',
            'price': '200',
          },
          {
            'name': 'Zhangjiajie National Forest Park',
            'description': 'Inspiration for Avatar\'s floating mountains, featuring unique sandstone pillars.',
            'image': 'assets/Zhangjiajie.png',
            'location': 'China',
            'price': '180',
          },
          {
            'name': 'Fiordland National Park',
            'description': 'New Zealand\'s largest national park with stunning fjords and waterfalls.',
            'image': 'assets/fiordland.png',
            'location': 'New Zealand',
            'price': '160',
          },
          {
            'name': 'Grand Canyon National Park',
            'description': 'Iconic natural wonder with breathtaking views and geological history.',
            'image': 'assets/grandcanyon.png',
            'location': 'USA',
            'price': '140',
          },
          {
            'name': 'Masai Mara Reserve',
            'description': 'Famous for the Great Migration and abundant wildlife in Kenya.',
            'image': 'assets/masai.png',
            'location': 'Kenya',
            'price': '170',
          },
          {
            'name': 'Serengeti National Park',
            'description': 'Tanzania\'s premier wildlife destination with vast savannahs and wildlife.',
            'image': 'assets/serengeti.png',
            'location': 'Tanzania',
            'price': '190',
          },
        ];

        for (final park in sampleParks) {
          await FirebaseFirestore.instance.collection('parks').add(park);
        }
        print('Sample parks added to database');
      }
    } catch (e) {
      print('Error checking/populating parks: $e');
    }
  }

  void _initFCM() async {
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      if (message.notification != null) {
        print('Notification title: 4{message.notification!.title}');
        print('Notification body: 4{message.notification!.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.notification!.title ?? 'New Notification')),
        );
      }
    });
  }

  // Demo top parks data
  final List<Map<String, String>> topParks = [
    {
      'name': 'Fiordland National Park',
      'image': 'assets/fiordland.png',
      'location': 'New Zealand',
    },
    {
      'name': 'Grand Canyon National Park',
      'image': 'assets/grandcanyon.png',
      'location': 'USA',
    },
    {
      'name': 'Masai Mara Reserve',
      'image': 'assets/masai.png',
      'location': 'Kenya',
    },
    {
      'name': 'Serengeti National Park',
      'image': 'assets/serengeti.png',
      'location': 'Tanzania',
    },
    {
      'name': 'Kruger National Park',
      'image': 'assets/kruger.png',
      'location': 'South Africa',
    },
    {
      'name': 'Jim Corbett National Park',
      'image': 'assets/JimCorbett.png',
      'location': 'India',
    },
    {
      'name': 'Volcanoes National Park',
      'image': 'assets/volcanoes.png',
      'location': 'Rwanda',
    },
    {
      'name': 'Zhangjiajie National Forest Park',
      'image': 'assets/Zhangjiajie.png',
      'location': 'China',
    },
  ];

  // Hardcoded nearest parks data
  final List<Map<String, String>> nearestParks = [
    {
      'name': 'Kruger National Park',
      'image': 'assets/kruger.png',
      'location': 'South Africa',
      'description': 'One of Africa\'s largest game reserves, home to the Big Five and diverse wildlife.',
      'price': '150',
    },
    {
      'name': 'Jim Corbett National Park',
      'image': 'assets/JimCorbett.png',
      'location': 'India',
      'description': 'India\'s oldest national park, famous for Bengal tigers and rich biodiversity.',
      'price': '120',
    },
    {
      'name': 'Volcanoes National Park',
      'image': 'assets/volcanoes.png',
      'location': 'Rwanda',
      'description': 'Home to endangered mountain gorillas and stunning volcanic landscapes.',
      'price': '200',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTravelGadgets(BuildContext context) {
    final theme = Theme.of(context);
    final gadgets = [
      {'icon': Icons.train, 'label': 'Railway', 'screen': RailwayScreen()},
      {'icon': Icons.flight, 'label': 'Airway', 'screen': AirwayScreen()},
      {'icon': Icons.directions_boat, 'label': 'Seaway', 'screen': SeawayScreen()},
      {'icon': Icons.directions_car, 'label': 'Road', 'screen': RoadScreen()},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: gadgets.map((gadget) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => gadget['screen'] as Widget)),
                child: CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  radius: 28,
                  child: Icon(gadget['icon'] as IconData, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 4),
              Text(gadget['label'] as String, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMapSection() {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(center: LatLng(0, 0), zoom: 2),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/serengeti_bg.jpg'),
              fit: BoxFit.cover,
              colorFilter: theme.brightness == Brightness.dark
                  ? ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)
                  : null,
            ),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Traveler',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Explore parks around you!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 36,
          right: 20,
          child: CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/avatar.png'),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 20,
          right: 20,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Park',
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.iconTheme.color),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                fillColor: theme.cardColor,
                filled: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              style: theme.textTheme.bodyMedium,
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim();
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _searchText = value.trim();
                });
                // Hide keyboard after search
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopParks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            'Top Parks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topParks.length,
            separatorBuilder: (_, __) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              final park = topParks[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripDetailScreen(
                        park: {
                          'name': park['name']!,
                          'image': park['image']!,
                          'location': park['location']!,
                          'description': 'A beautiful park to explore.',
                          'price': '100',
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(park['image']!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        park['name']!,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildTopSection(),
          SizedBox(height: 8),
          _buildTopParks(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearest Parks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                if (_searchText.isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // This will show all parks since search is empty
                    },
                    icon: Icon(Icons.visibility, size: 16, color: AppColors.primary),
                    label: Text(
                      'View All',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _searchText.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: nearestParks.length,
                    itemBuilder: (context, index) {
                      final park = nearestParks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailScreen(park: park),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (park['image'] != null && park['image']!.isNotEmpty)
                                Image.asset(
                                  park['image']!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 180,
                                    color: AppColors.lightGrey,
                                    child: const Icon(Icons.image, size: 80, color: AppColors.grey),
                                  ),
                                )
                              else
                                Container(
                                  height: 180,
                                  color: AppColors.lightGrey,
                                  child: const Icon(Icons.image, size: 80, color: AppColors.grey),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      park['name'] ?? 'Unknown Park',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      park['description'] ?? '',
                                      style: TextStyle(fontSize: 15, color: AppColors.text),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Location: ${park['location'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    if (park['price'] != null)
                                      Text(
                                        'Price: \$${park['price']}',
                                        style: TextStyle(fontSize: 15, color: AppColors.success, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('parks').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF234F1E)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('No parks found.'));
                      }
                      
                      // Filter parks based on search text
                      List<QueryDocumentSnapshot> parks = snapshot.data!.docs;
                      parks = parks.where((doc) {
                        final park = doc.data() as Map<String, dynamic>;
                        final name = (park['name'] ?? '').toString().toLowerCase();
                        final location = (park['location'] ?? '').toString().toLowerCase();
                        final description = (park['description'] ?? '').toString().toLowerCase();
                        final searchLower = _searchText.toLowerCase();
                        
                        // Enhanced search: check for exact matches first, then partial matches
                        if (name.startsWith(searchLower) || location.startsWith(searchLower)) {
                          return true; // Exact start match gets priority
                        }
                        
                        return name.contains(searchLower) || 
                               location.contains(searchLower) || 
                               description.contains(searchLower);
                      }).toList();
                      
                      // Sort results: exact matches first, then partial matches
                      parks.sort((a, b) {
                        final parkA = a.data() as Map<String, dynamic>;
                        final parkB = b.data() as Map<String, dynamic>;
                        final nameA = (parkA['name'] ?? '').toString().toLowerCase();
                        final nameB = (parkB['name'] ?? '').toString().toLowerCase();
                        final locationA = (parkA['location'] ?? '').toString().toLowerCase();
                        final locationB = (parkB['location'] ?? '').toString().toLowerCase();
                        final searchLower = _searchText.toLowerCase();
                        
                        // Check if A starts with search term
                        final aStartsWith = nameA.startsWith(searchLower) || locationA.startsWith(searchLower);
                        final bStartsWith = nameB.startsWith(searchLower) || locationB.startsWith(searchLower);
                        
                        if (aStartsWith && !bStartsWith) return -1;
                        if (!aStartsWith && bStartsWith) return 1;
                        return 0;
                      });
                      
                      // Add search results header
                      Widget searchHeader = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Search Results for "$_searchText"',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${parks.length} found',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (parks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'No parks found for "$_searchText"',
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try searching for a different park name, location, or description',
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Popular searches:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _searchSuggestions
                                    .where((suggestion) => suggestion.toLowerCase().contains(_searchText.toLowerCase()))
                                    .take(6)
                                    .map((suggestion) => GestureDetector(
                                          onTap: () {
                                            _searchController.text = suggestion;
                                            setState(() {
                                              _searchText = suggestion;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              suggestion,
                                              style: TextStyle(fontSize: 12, color: AppColors.primary),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                        children: [
                          searchHeader,
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                              itemCount: parks.length,
                              itemBuilder: (context, index) {
                                final park = parks[index].data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 6,
                                  shadowColor: AppColors.primary.withOpacity(0.3),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TripDetailScreen(park: park.map((k, v) => MapEntry(k, v.toString()))),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (park['image'] != null && park['image'].toString().isNotEmpty)
                                          Image.asset(
                                            park['image'],
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 180,
                                              color: AppColors.lightGrey,
                                              child: const Icon(Icons.image, size: 80, color: AppColors.grey),
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 180,
                                            color: AppColors.lightGrey,
                                            child: const Icon(Icons.image, size: 80, color: AppColors.grey),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                park['name'] ?? 'Unknown Park',
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                park['description'] ?? '',
                                                style: TextStyle(fontSize: 15, color: AppColors.text),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Location: ${park['location'] ?? 'N/A'}',
                                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                              ),
                                              if (park['price'] != null)
                                                Text(
                                                  'Price: \$${park['price']}',
                                                  style: TextStyle(fontSize: 15, color: AppColors.success, fontWeight: FontWeight.bold),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  late final List<Widget> _widgetOptions = <Widget>[
    _buildHomeTab(),
    const BookingsScreen(),
    const NotificationScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5EC2B7), // Teal background from UI kit
      body: SafeArea(
        child: Column(
          children: [
            // Removed the header card
            // Padding(
            //   ...
            // ),
            // Start directly with the search bar and content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Theme.of(context).cardColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// Placeholder screens for travel gadgets
class RailwayScreen extends StatelessWidget {
  const RailwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Railway'), backgroundColor: AppColors.primary),
      body: Center(child: Text('Railway trips coming soon!', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
    );
  }
}
class AirwayScreen extends StatelessWidget {
  const AirwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Airway'), backgroundColor: AppColors.primary),
      body: Center(child: Text('Airway trips coming soon!', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
    );
  }
}
class SeawayScreen extends StatelessWidget {
  const SeawayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Seaway'), backgroundColor: AppColors.primary),
      body: Center(child: Text('Seaway trips coming soon!', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
    );
  }
}
class RoadScreen extends StatelessWidget {
  const RoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Road'), backgroundColor: AppColors.primary),
      body: Center(child: Text('Road trips coming soon!', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
    );
  }
}
