import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'search_page.dart';
import 'nearby_vendors_page.dart';
import 'my_orders_page.dart';
import 'food_stories_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _search(BuildContext context) {
    final query = _searchController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(initialQuery: query),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C7B7B),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF9C7B7B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
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
            // Welcome message with user email
            Builder(
              builder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Welcome, ${user.email}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            const Text(
              'Discover authentic flavors near you',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(context),
                decoration: InputDecoration(
                  hintText: 'Search by food name or culture',
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.black54),
                    onPressed: () => _search(context),
                  ),
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
            const SizedBox(height: 20),
            // Main buttons grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _HomeButton(
                      color: const Color(0xFFD1A6A6),
                      icon: Icons.search,
                      label: 'Search',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage()),
                        );
                      },
                    ),
                    _HomeButton(
                      color: const Color(0xFF6B6BD6),
                      icon: Icons.home,
                      label: 'Nearby Vendors',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NearbyVendorsPage()),
                        );
                      },
                    ),
                    _HomeButton(
                      color: const Color(0xFF6B8ED6),
                      iconAsset: 'assets/images/plates.png',
                      label: 'My Orders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                        );
                      },
                    ),
                    _HomeButton(
                      color: const Color(0xFF1CB48C),
                      iconAsset: 'assets/images/books.png',
                      label: 'Food Stories',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FoodStoriesPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF9C7B7B),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.blue),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  final Color color;
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    Key? key,
    required this.color,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _isPressed 
            ? Matrix4.identity() * Matrix4.diagonal3Values(0.95, 0.95, 1.0)
            : Matrix4.identity(),
        child: Material(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null)
                  Icon(widget.icon, size: 36, color: Colors.black)
                else if (widget.iconAsset != null)
                  Image.asset(
                    widget.iconAsset!,
                    width: 36,
                    height: 36,
                  ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 