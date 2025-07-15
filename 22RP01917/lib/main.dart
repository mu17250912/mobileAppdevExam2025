import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'product_management_screen.dart';
import 'user_product_catalog.dart';
import 'admin_booking_management.dart';
import 'user_auth.dart';
import 'rwanda_colors.dart';
import 'widgets/ad_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyALO2UfVHWqDGK3LdiyrZjBlG8Z6-DcKSg",
      authDomain: "shop-management-app-70bca.firebaseapp.com",
      projectId: "shop-management-app-70bca",
      storageBucket: "shop-management-app-70bca.appspot.com",
      messagingSenderId: "982617806837",
      appId: "1:982617806837:web:b17d279f7490a608ddf2bc",
    ),
  );
  MobileAds.instance.initialize(); // Initialize AdMob
  runApp(MyAppWithAnalytics());
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username == 'billy' && password == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      setState(() {
        _error = 'Invalid credentials';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: const Text('Admin Login', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kRwandaBlue.withOpacity(0.07),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                // Logo and app name
                FlutterLogo(size: 64),
                const SizedBox(height: 12),
                const Text('Shop Management App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kRwandaBlue)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kRwandaBlue)),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRwandaBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _login,
                            child: const Text('Admin Login', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRwandaYellow,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UserAuthScreen()),
                              );
                            },
                            child: const Text('User Login / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Announcement Message'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final msg = controller.text.trim();
              if (msg.isNotEmpty) {
                await FirebaseFirestore.instance.collection('announcements').add({
                  'message': msg,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement sent!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _dashboardStats() async* {
    final productsSnap = await FirebaseFirestore.instance.collection('products').get();
    final bookingsSnap = await FirebaseFirestore.instance.collection('bookings').get();
    int totalProducts = productsSnap.docs.length;
    int totalQuantity = 0;
    for (final doc in productsSnap.docs) {
      final data = doc.data();
      totalQuantity += (data['quantity'] ?? 0) as int;
    }
    int totalBookings = bookingsSnap.docs.length;
    int pending = 0, completed = 0, canceled = 0;
    double totalCommission = 0;
    for (final doc in bookingsSnap.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'Pending';
      if (status == 'Pending') pending++;
      if (status == 'Completed') completed++;
      if (status == 'Canceled') canceled++;
      totalCommission += double.tryParse(data['commission']?.toString() ?? '0') ?? 0;
    }
    yield {
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
      'totalBookings': totalBookings,
      'pending': pending,
      'completed': completed,
      'canceled': canceled,
      'totalCommission': totalCommission,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kRwandaBlue,
        title: Row(
          children: [
            const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
            const Spacer(),
            Icon(Icons.wb_sunny, color: kRwandaSun, size: 32),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: Stream.periodic(const Duration(seconds: 2)).asyncMap((_) => _dashboardStats().first),
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return Container(
            color: kRwandaBlue.withOpacity(0.07),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (stats != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                          label: 'Products',
                          value: stats['totalProducts'].toString(),
                          color: kRwandaBlue,
                          icon: Icons.shopping_bag,
                        ),
                        _StatCard(
                          label: 'Bookings',
                          value: stats['totalBookings'].toString(),
                          color: kRwandaYellow,
                          icon: Icons.book_online,
                        ),
                        _StatCard(
                          label: 'Commission',
                          value: '\$${stats['totalCommission'].toStringAsFixed(2)}',
                          color: kRwandaGreen,
                          icon: Icons.attach_money,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MiniStat(label: 'Pending', value: stats['pending'].toString(), color: kRwandaYellow),
                        _MiniStat(label: 'Completed', value: stats['completed'].toString(), color: kRwandaGreen),
                        _MiniStat(label: 'Canceled', value: stats['canceled'].toString(), color: Colors.redAccent),
                        _MiniStat(label: 'Quantity', value: stats['totalQuantity'].toString(), color: kRwandaBlue),
                      ],
                    ),
                  ),
                ],
                // Feedback section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: kRwandaYellow.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text('Recent Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error:  {snapshot.error}'));
                            }
                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(child: Text('No feedback yet.'));
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final entry = FeedbackEntry.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                                return Card(
                                  color: kRwandaBlue.withOpacity(0.08),
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(5, (i) => Icon(
                                        i < entry.rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      )),
                                    ),
                                    title: Text(entry.comment),
                                    subtitle: Text('User:  {entry.userId}\nTime:  {entry.timestamp ?? ''}'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: kRwandaGreen.withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text('Referral Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error:  {snapshot.error}'));
                            }
                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(child: Text('No users yet.'));
                            }
                            final Map<String, int> referralCounts = {};
                            for (final doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final referredBy = data['referredBy'];
                              if (referredBy != null && referredBy is String) {
                                referralCounts[referredBy] = (referralCounts[referredBy] ?? 0) + 1;
                              }
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final user = docs[index].data() as Map<String, dynamic>;
                                final email = user['email'] ?? '';
                                final referralCode = user['referralCode'] ?? '';
                                final referredBy = user.containsKey('referredBy') ? user['referredBy'] : null;
                                final totalReferrals = referralCounts[referralCode] ?? 0;
                                return Card(
                                  color: kRwandaGreen.withOpacity(0.08),
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(email),
                                    subtitle: Text('Referral Code: $referralCode\nReferred By: ${referredBy ?? '-'}\nTotal Referrals: $totalReferrals'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kRwandaYellow,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
                                  );
                                },
                                child: const Text('Manage Products'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kRwandaGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminBookingManagement()),
                                  );
                                },
                                child: const Text('Manage Bookings'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kRwandaBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 2,
                                ),
                                onPressed: () => _showAnnouncementDialog(context),
                                child: const Text('Send Announcement'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdBanner(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Rwanda flag styled stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: 110,
        height: 90,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }
}

class FeedbackEntry {
  final String id;
  final String userId;
  final int rating;
  final String comment;
  final DateTime? timestamp;

  FeedbackEntry({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }

  factory FeedbackEntry.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedbackEntry(
      id: documentId,
      userId: map['userId'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : null,
    );
  }
}

class MyAppWithAnalytics extends StatelessWidget {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  MyAppWithAnalytics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AdminLoginScreen(),
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
