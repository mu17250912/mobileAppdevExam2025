import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:badges/badges.dart' as badges;

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  
  const SearchPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';
  String _sortBy = 'Name'; // Name, Rating, Price, Popularity
  double _minRating = 0.0;
  bool _showRatingFilter = false;
  bool _isPremiumBuyer = false;
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _fetchPremiumStatus();
    _listenNotifications();
  }

  Future<void> _fetchPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isPremiumBuyer = doc.data()?['isPremiumBuyer'] == true;
      });
    }
  }

  void _listenNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final notifs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
          setState(() {
            _notifications = notifs;
            _unreadNotificationCount = notifs.where((n) => n['read'] == false).length;
          });
        });
    }
  }

  void _showNotificationsModal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Mark all as read
    final unread = _notifications.where((n) => n['read'] == false).toList();
    for (final notif in unread) {
      await FirebaseFirestore.instance.collection('notifications').doc(notif['id']).update({'read': true});
    }
    setState(() {
      _unreadNotificationCount = 0;
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: _notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return ListTile(
                        leading: Icon(
                          notif['type'] == 'order' ? Icons.shopping_cart : Icons.notifications,
                          color: notif['read'] == false ? Colors.blue : Colors.grey,
                        ),
                        title: Text(notif['title'] ?? ''),
                        subtitle: Text(notif['body'] ?? ''),
                        trailing: notif['read'] == false
                          ? Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            )
                          : null,
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> products) {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered = products;
    
    // Apply search filter
    if (_filter == 'All') {
      filtered = filtered.where((product) =>
        (product['name'] ?? '').toString().toLowerCase().contains(query) ||
        (product['vendorType'] ?? '').toString().toLowerCase().contains(query) ||
        (product['vendorLocation'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    } else if (_filter == 'By Product Name') {
      filtered = filtered.where((product) =>
        (product['name'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    } else if (_filter == 'By Vendor Type') {
      filtered = filtered.where((product) =>
        (product['vendorType'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    } else if (_filter == 'By Vendor Location') {
      filtered = filtered.where((product) =>
        (product['vendorLocation'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    }

    // Apply rating filter
    if (_minRating > 0) {
      filtered = filtered.where((product) {
        final rating = (product['rating'] ?? 0.0).toDouble();
        return rating >= _minRating;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Rating':
          final ratingA = (a['rating'] ?? 0.0).toDouble();
          final ratingB = (b['rating'] ?? 0.0).toDouble();
          return ratingB.compareTo(ratingA); // Highest first
        case 'Price':
          final priceA = (a['price'] ?? 0).toInt();
          final priceB = (b['price'] ?? 0).toInt();
          return priceA.compareTo(priceB); // Lowest first
        case 'Popularity':
          final reviewCountA = (a['reviewCount'] ?? 0).toInt();
          final reviewCountB = (b['reviewCount'] ?? 0).toInt();
          return reviewCountB.compareTo(reviewCountA); // Most reviewed first
        case 'Name':
        default:
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
      }
    });

    return filtered;
  }

  Widget _buildStarRating(double rating, {double size = 16.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  void _showRatingDialog(Map<String, dynamic> product) {
    double userRating = 0.0;
    final reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStarRating(userRating, size: 32.0),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        userRating = index + 1.0;
                      });
                    },
                    child: Icon(
                      index < userRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32.0,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Write a review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: userRating > 0 ? () async {
                await _submitRating(product, userRating, reviewController.text);
                Navigator.pop(context);
              } : null,
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(Map<String, dynamic> product, double rating, String review) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to rate products')),
        );
        return;
      }

      // Add review to reviews collection
      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': product['id'],
        'userId': user.uid,
        'userEmail': user.email,
        'rating': rating,
        'review': review,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update product's average rating and review count
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: product['id'])
          .get();

      final reviews = reviewsSnapshot.docs;
      final totalRating = reviews.fold<double>(0, (sum, doc) => sum + (doc.data()['rating'] ?? 0.0));
      final averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;

      await FirebaseFirestore.instance
          .collection('products')
          .doc(product['id'])
          .update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              product['image'] ?? 'assets/images/platefood.png',
              width: 200,
              height: 120,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStarRating((product['rating'] ?? 0.0).toDouble()),
                const SizedBox(width: 8),
                Text('(${product['reviewCount'] ?? 0} reviews)'),
              ],
            ),
            const SizedBox(height: 8),
            if (product['vendorType'] != null)
              Text('Vendor Type: ${product['vendorType']}'),
            if (product['vendorLocation'] != null)
              Text('Vendor Location: ${product['vendorLocation']}'),
            if (product['vendorEmail'] != null)
              Text('Vendor: ${product['vendorEmail']}'),
            if (product['desc'] != null)
              Text('Description: ${product['desc']}'),
            Text('Price: ${product['price'] ?? ''} FRW'),
            Text(product['inStock'] == true ? 'In Stock' : 'Out of Stock'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRatingDialog(product);
            },
            child: const Text('Rate Product'),
          ),
          ElevatedButton(
            onPressed: product['inStock'] == true ? () async {
              Navigator.pop(context);
              // Save order to Firestore
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to place an order.')),
                  );
                  return;
                }
                await FirebaseFirestore.instance.collection('orders').add({
                  'foodName': product['name'],
                  'vendorId': product['vendorId'],
                  'vendorEmail': product['vendorEmail'],
                  'vendorType': product['vendorType'],
                  'vendorLocation': product['vendorLocation'],
                  'desc': product['desc'],
                  'image': product['image'],
                  'price': product['price'],
                  'status': 'Preparing',
                  'orderTime': DateTime.now().toIso8601String(),
                  'buyerId': user.uid,
                  'buyerEmail': user.email,
                });
                // Add notification for the user
                await FirebaseFirestore.instance.collection('notifications').add({
                  'userId': user.uid,
                  'title': 'Order Placed',
                  'body': 'You have ordered ${product['name']} for ${product['price']} FRW.',
                  'timestamp': FieldValue.serverTimestamp(),
                  'read': false,
                  'type': 'order',
                  'productId': product['id'],
                });
                // Log analytics event
                await FirebaseAnalytics.instance.logEvent(
                  name: 'order_placed',
                  parameters: {
                    'foodName': product['name'],
                    'price': product['price'],
                    'buyerId': user.uid,
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order placed for ${product['name']}!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to place order. Please try again.')),
                );
              }
            } : null,
            child: const Text('Order Now'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C7B7B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _showRatingFilter ? Icons.filter_list : Icons.filter_list_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showRatingFilter = !_showRatingFilter;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Image.asset(
            'assets/images/logo1.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 8),
          const Text(
            'T-Find',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8800),
            ),
          ),
          const SizedBox(height: 8),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by product, vendor type, or location',
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.grey[300],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filter == 'All',
                    onSelected: (_) => setState(() => _filter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('By Product Name'),
                    selected: _filter == 'By Product Name',
                    onSelected: (_) => setState(() => _filter = 'By Product Name'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('By Vendor Type'),
                    selected: _filter == 'By Vendor Type',
                    onSelected: (_) => setState(() => _filter = 'By Vendor Type'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('By Vendor Location'),
                    selected: _filter == 'By Vendor Location',
                    onSelected: (_) => setState(() => _filter = 'By Vendor Location'),
                  ),
                ],
              ),
            ),
          ),
          // Sort and Rating Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Name', 'Rating', 'Price', 'Popularity'].map((sort) {
                      return DropdownMenuItem(value: sort, child: Text(sort));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
                if (_showRatingFilter) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Min Rating: ${_minRating.toStringAsFixed(1)}'),
                        Slider(
                          value: _minRating,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search Results
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Search Results',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                final products = productSnapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    ...data,
                    'id': doc.id,
                  };
                }).toList();
                // Fetch users and merge vendor info
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final userDocs = userSnapshot.data?.docs ?? [];
                    final Map<String, Map<String, dynamic>> userInfo = {
                      for (var doc in userDocs)
                        doc.id: doc.data() as Map<String, dynamic>
                    };
                    // Merge vendor type and location into each product
                    final mergedProducts = products.map((product) {
                      final vendorId = product['vendorId'];
                      final user = userInfo[vendorId] ?? {};
                      return {
                        ...product,
                        'vendorType': user['type'] ?? '',
                        'vendorLocation': user['location'] ?? '',
                      };
                    }).toList();
                    final filteredProducts = _applyFilter(mergedProducts);
                    if (filteredProducts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Try adjusting your search or filter',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  product['image'] ?? 'assets/images/platefood.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildStarRating((product['rating'] ?? 0.0).toDouble()),
                                      const SizedBox(width: 8),
                                      Text('(${product['reviewCount'] ?? 0})'),
                                    ],
                                  ),
                                  if (_isPremiumBuyer && (product['premiumDeal'] == true || product['discountPrice'] != null)) ...[
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('Premium Deal', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        if (product['discountPrice'] != null)
                                          Text('Now: ${product['discountPrice']} FRW', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    if (product['discountPrice'] != null)
                                      Text('Was: ${product['price']} FRW', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                  ]
                                  else ...[
                                    Text('Price: ${product['price']} FRW'),
                                  ],
                                  Text(product['inStock'] == true ? 'In Stock' : 'Out of Stock'),
                                  if ((product['vendorType'] ?? '').isNotEmpty)
                                    Text('Type: ${product['vendorType']}'),
                                  if ((product['vendorLocation'] ?? '').isNotEmpty)
                                    Text('Location: ${product['vendorLocation']}'),
                                ],
                              ),
                              trailing: const Icon(Icons.shopping_cart, color: Colors.amber, size: 20),
                              onTap: () => _showProductDetails(product),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            _showNotificationsModal();
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: badges.Badge(
              showBadge: _unreadNotificationCount > 0,
              badgeContent: Text(
                _unreadNotificationCount > 0 ? _unreadNotificationCount.toString() : '',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications_none),
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
} 