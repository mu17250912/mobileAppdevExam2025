// Modified HomeScreen with Notification Manager integration and custom SettingsScreen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'subscription_screen.dart';
import 'notifications_screen.dart';
import '../notifications_manager.dart';
import '../favorites_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isOffline = false;
  bool isDarkMode = false;
  List<dynamic> onlineBooks = [];
  List<Map<String, dynamic>> borrowedBooks = [];
  List<String> notifications = [];
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchOnlineBooks();
    fetchFirestoreData();
  }

  Future<void> fetchOnlineBooks() async {
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=subject:education');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          onlineBooks = data['items'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching online books: \$e');
    }
  }

  Future<void> fetchFirestoreData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final borrowedSnap = await FirebaseFirestore.instance
        .collection('borrowed_books')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    final borrowed = borrowedSnap.docs.map((doc) => {
      'title': doc['title'],
      'fileUrl': doc['fileUrl'],
    }).toList();

    final notifSnap = await FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    final notifList = notifSnap.docs.map((doc) => doc['message'].toString()).toList();

    setState(() {
      borrowedBooks = borrowed;
      notifications = notifList;
    });
  }

  // The rest of the code remains the same
  // Full file has been stored and can be enhanced incrementally


  Future<void> _openUrl(String urlStr) async {
    // Log analytics event for opening a book
    analytics.logEvent(name: 'open_book', parameters: {'url': urlStr});
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open book info')),
      );
    }
  }

void showBorrowedBooks() {
  print("Borrowed books length: ${borrowedBooks.length}");

  showModalBottomSheet(
    context: context,
    builder: (context) => borrowedBooks.isEmpty
        ? const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No borrowed books found for your account.'),
          ))
        : ListView(
            children: borrowedBooks.map((book) {
              return ListTile(
                title: Text(book['title'] ?? 'No title'),
                trailing: IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () {
                    final url = book['fileUrl'] ?? '';
                    if (url.isNotEmpty) {
                      _openUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid book URL")),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
  );
}


  void showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: notifications.isEmpty
                    ? const ListTile(title: Text('No notifications'))
                    : Column(
                        children: notifications.map((note) => ListTile(
                          leading: const Icon(Icons.notifications, color: Colors.green),
                          title: Text(note),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 24),
              Text('Your Borrowed Books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: borrowedBooks.isEmpty
                    ? const ListTile(title: Text('No borrowed books'))
                    : Column(
                        children: borrowedBooks.map((book) => ListTile(
                          leading: const Icon(Icons.book, color: Colors.blue),
                          title: Text(book['title'] ?? 'No title'),
                          trailing: IconButton(
                            icon: const Icon(Icons.picture_as_pdf),
                            onPressed: () => _openUrl(book['fileUrl']),
                          ),
                        )).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ... continued (I will send next chunk shortly to complete all 744 lines)


  void showProfileInfo() {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Profile Information"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(user!.photoURL!),
              )
            else
              const CircleAvatar(
                radius: 36,
                child: Icon(Icons.person, size: 36),
              ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text("Phone: +250 788 123 456"),
            const Text("Address: Kigali, Rwanda"),
            const Text("Support: support@example.com"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  void addNotification(String message) {
    setState(() {
      notifications.add(message);
    });
  }

  Future<void> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/${user!.uid}.jpg');
      await ref.putData(await pickedFile.readAsBytes());
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      setState(() {}); // Refresh UI
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    }
  }

  void showBuyDialog(String title, String price) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Buy "$title"',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              Text('Price: $price', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _paymentMethodTile(
                    context,
                    icon: Image.asset('assets/momo.png', height: 40, errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.green)),
                    label: 'MoMo',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showMomoDialog(context, title, price);
                    },
                  ),
                  _paymentMethodTile(
                    context,
                    icon: Image.asset('assets/paypal.png', height: 40, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.blue)),
                    label: 'PayPal',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showPayPalDialog(context, title, price);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile(BuildContext context, {required Widget icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showMomoDialog(BuildContext context, String title, String price) {
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/momo.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.green)),
            const SizedBox(width: 8),
            const Text('MoMo Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your MoMo number and PIN to proceed with payment of $price.'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'MoMo Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'MoMo PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty || pinController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter all required details.')));
                return;
              }
              Navigator.pop(dialogContext);
              _showPaymentConfirmation(context, 'MoMo', title, price, 'Number:  2${phoneController.text}, PIN: ${pinController.text}');
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showPayPalDialog(BuildContext context, String title, String price) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/paypal.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.blue)),
            const SizedBox(width: 8),
            const Text('PayPal Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your PayPal email to proceed with payment of $price.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'PayPal Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your PayPal email.')));
                return;
              }
              Navigator.pop(dialogContext);
              _showPaymentConfirmation(context, 'PayPal', title, price, 'Email: ${emailController.text}');
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context, String method, String title, String price, String details) {
    NotificationsManager.add(
      title: 'Payment Successful',
      message: '[$method] Payment for "$title" of $price. Details: $details',
      type: 'payment',
      imageUrl: null,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$method Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: $title'),
            Text('Amount: $price'),
            Text('Details: $details'),
            const SizedBox(height: 16),
            const Text('Payment confirmation has been sent to your notifications.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('[$method] Payment confirmation sent to notifications.'),
      backgroundColor: Colors.blue[800],
    ));
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Books',
            onPressed: () async {
              String? query = await showDialog<String>(
                context: context,
                builder: (context) {
                  String input = '';
                  return AlertDialog(
                    title: const Text('Search Books Online'),
                    content: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Enter book title, author, or keyword'),
                      onChanged: (value) => input = value,
                      onSubmitted: (value) => Navigator.of(context).pop(value),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(input),
                        child: const Text('Search'),
                      ),
                    ],
                  );
                },
              );
              if (query != null && query.trim().isNotEmpty) {
                // Log analytics event for book search
                analytics.logEvent(name: 'search_book', parameters: {'query': query.trim()});
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      // Fetch all books in 'Categories' collection, then filter client-side
                      future: FirebaseFirestore.instance
                          .collection('Categories')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const AlertDialog(
                            content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                          );
                        }
                        if (snapshot.hasError) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: Text('Failed to search books: \\${snapshot.error}'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                          );
                        }
                        final allBooks = snapshot.data?.docs ?? [];
                        final q = query!.toLowerCase();
                        final filtered = allBooks.where((doc) {
                          final book = doc.data();
                          final title = (book['title'] ?? '').toString().toLowerCase();
                          final author = (book['author'] ?? '').toString().toLowerCase();
                          final desc = (book['description'] ?? '').toString().toLowerCase();
                          return title.contains(q) || author.contains(q) || desc.contains(q);
                        }).toList();
                        if (filtered.isEmpty) {
                          return AlertDialog(
                            title: const Text('No Results'),
                            content: const Text('No books found for your search.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                          );
                        }
                        return AlertDialog(
                          title: Text('Found \\${filtered.length} book(s)'),
                          content: SizedBox(
                            width: 320,
                            height: 300,
                            child: ListView.separated(
                              separatorBuilder: (_, __) => const Divider(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final book = filtered[index].data();
                                return ListTile(
                                  leading: (book['imageUrl'] != null && book['imageUrl'].toString().isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(book['imageUrl'], width: 36, height: 48, fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.book, color: Colors.blueAccent, size: 32),
                                  title: Text(book['title'] ?? 'No Title'),
                                  subtitle: Text(book['author'] != null && book['author'].toString().isNotEmpty ? 'By ' + book['author'] : ''),
                                  trailing: book['fileUrl'] != null && book['fileUrl'].toString().isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.open_in_new, color: Colors.blue),
                                          tooltip: 'Open Book',
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _openUrl(book['fileUrl']);
                                          },
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            child: const Text('Subscription'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          StreamBuilder<List<NotificationItem>>(
            stream: NotificationsManager.stream(unreadOnly: true),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final hasNotifications = notifications.isNotEmpty;
              return Stack(
                children: [
                  IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(),
                          ),
                        );
                      },
                  ),
                  if (hasNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          notifications.length > 9 ? '9+' : notifications.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: showProfileInfo,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    isOffline: isOffline,
                    isDarkMode: themeNotifier.value == ThemeMode.dark,
                    onChanged: (offline, dark) {
                      setState(() {
                        isOffline = offline;
                        themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountEmail: Text(user?.email ?? 'Guest'),
              currentAccountPicture: user?.photoURL != null
                  ? CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
                  : const CircleAvatar(child: Icon(Icons.person)),
              accountName: Text(user?.displayName ?? "Welcome!"),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Books'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Borrowed Books'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('You must be logged in to view borrowed books.'),
                      ));
                    }
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                        .collection('borrowed_books')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No borrowed books found for your account.'),
                          ));
                        }
                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: docs.map((doc) {
                            final book = doc.data();
                            return ListTile(
                              leading: const Icon(Icons.book, color: Colors.blue),
                              title: Text(book['title'] ?? 'No title'),
                              trailing: IconButton(
                                icon: const Icon(Icons.picture_as_pdf),
                                onPressed: () async {
                                  final url = book['fileUrl'] ?? '';
                                  if (url.isNotEmpty) {
                                    final Uri uri = Uri.parse(url);
                                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not open book info')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid book URL')),
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo),
              title: const Text('Add Profile Picture'),
              onTap: pickAndUploadProfileImage,
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      isOffline: isOffline,
                      isDarkMode: isDarkMode,
                      onChanged: (offline, dark) {
                        setState(() {
                          isOffline = offline;
                          isDarkMode = dark;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Categories').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data()! as Map<String, dynamic>;
                    final title = data['title'] ?? 'No title';
                    final imageUrl = data['imageUrl'] ?? '';
                    final pdfUrl = data['fileUrl'] ?? '';

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(child: Icon(Icons.broken_image, size: 40)),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Center(child: Icon(Icons.menu_book, size: 40)),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 34,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 0),
                                        minimumSize: const Size(0, 34),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (pdfUrl.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('PDF URL is empty')),
                                          );
                                          return;
                                        }
                                        final Uri url = Uri.parse(pdfUrl);
                                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open PDF')),
                                          );
                                        } else {
                                          addNotification('You read the book: $title');
                                        }
                                      },
                                      icon: const Icon(Icons.menu_book, size: 16),
                                      label: const Text('Read', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SizedBox(
                                    height: 34,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue[700],
                                        side: BorderSide(color: Colors.blue[700]!, width: 1.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 0),
                                        minimumSize: const Size(0, 34),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;
                                        await FirebaseFirestore.instance.collection('borrowed_books').add({
                                          'userId': user.uid,
                                          'title': title,
                                          'fileUrl': pdfUrl,
                                          'timestamp': FieldValue.serverTimestamp(),
                                        });
                                        NotificationsManager.add(
                                          title: 'Book Borrowed',
                                          message: 'You borrowed "$title".',
                                          type: 'borrow',
                                          imageUrl: imageUrl,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$title has been borrowed')),
                                        );
                                      },
                                      icon: const Icon(Icons.shopping_bag, size: 15),
                                      label: const Text('Borrow', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SizedBox(
                                    height: 34,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 251, 25, 25),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 0),
                                        minimumSize: const Size(0, 34),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        showBuyDialog(title, '');
                                      },
                                      icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                                      label: const Text('Buy', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Other Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: onlineBooks.length,
                itemBuilder: (context, index) {
                  final book = onlineBooks[index];
                  final title = book['volumeInfo']?['title'] ?? 'No Title';
                  final thumbnail = book['volumeInfo']?['imageLinks']?['thumbnail'];
                  final infoLink = book['volumeInfo']?['infoLink'];

                  return ListTile(
                    leading: thumbnail != null
                        ? Image.network(
                            thumbnail,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.book),
                          )
                        : const Icon(Icons.book, size: 50),
                    title: Text(title),
                    trailing: ElevatedButton.icon(
                      onPressed: infoLink != null && infoLink.isNotEmpty
                          ? () async {
                              await FavoritesManager.addFavorite(
                                title: title,
                                fileUrl: infoLink,
                                imageUrl: thumbnail,
                              );
                              _openUrl(infoLink);
                            }
                          : null,
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Info"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Library'),

          BottomNavigationBarItem(
            icon: IconButton(
              icon: const Icon(Icons.person),
              onPressed: showProfileInfo,
            ),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            _showLibrary();
          }
        },
      ),
    );
  }




  void _showLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.8;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('Categories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final books = snapshot.data?.docs ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    color: Colors.blue[50],
                    child: const Text(
                      'Available books in eSoma library',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: books.isEmpty
                        ? const Center(child: Text('No books available in library.'))
                        : ListView.separated(
                            itemCount: books.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final book = books[index].data();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    (book['imageUrl'] != null && book['imageUrl'].toString().isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(book['imageUrl'], width: 48, height: 60, fit: BoxFit.cover),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 60,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.book, color: Colors.blueAccent, size: 32),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book['title'] ?? 'No Title',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => _openUrl(book['fileUrl'] ?? ''),
                                            child: Text(
                                              book['fileUrl'] ?? '',
                                              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

}