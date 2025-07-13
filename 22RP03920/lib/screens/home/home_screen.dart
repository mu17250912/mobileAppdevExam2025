import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert'; // Added for jsonEncode and jsonDecode
import 'package:http/http.dart' as http; // Added for http requests
import 'package:flutter/material.dart' as material;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;


// TESTING: This app was tested on Android 10, 11, 12 (emulator and real device), and on Chrome web.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  User? _user;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  BannerAd? _bannerAd;
  bool isPremium = false;
  // TODO: Set this to your real product ID from the Google Play Console (e.g., 'premium_upgrade')
  static const String kPremiumProductId = 'premium_upgrade';
  ProductDetails? _premiumProductDetails;
  bool _purchasePending = false;
  bool _isPaying = false;
  bool _hasPaidToday = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _user = _authService.getCurrentUser();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _bannerAd = BannerAd(
        adUnitId: 'test',
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(),
      )..load();
      _initializeInAppPurchase();
      _fetchProductDetails();
    }
    FirebaseAnalytics.instance.logScreenView(screenName: 'HomeScreen');
    _loadPremiumStatus();
    _checkIfPaidToday();
  }

  Future<void> _fetchProductDetails() async {
    final response = await InAppPurchase.instance.queryProductDetails({kPremiumProductId});
    if (response.notFoundIDs.isNotEmpty) {
      setState(() => _premiumProductDetails = null);
    } else {
      setState(() => _premiumProductDetails = response.productDetails.first);
    }
  }

  void _initializeInAppPurchase() {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    purchaseUpdated.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          await _setPremiumStatus(true);
          if (_user != null) {
            await _firestoreService.usersCollection.doc(_user!.uid).update({
              'isPremium': true,
              'premiumPurchasedAt': FieldValue.serverTimestamp(),
            });
          }
          FirebaseAnalytics.instance.logEvent(name: 'premium_purchase', parameters: {'method': 'in_app_purchase'});
          setState(() => _purchasePending = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium purchase successful!')));
        } else if (purchase.status == PurchaseStatus.pending) {
          setState(() => _purchasePending = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase pending...')));
        } else if (purchase.status == PurchaseStatus.error) {
          setState(() => _purchasePending = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase error: ${purchase.error?.message ?? 'Unknown error'}')));
        }
      }
    });
  }

  Future<void> _buyPremium() async {
    if (_premiumProductDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium product not found. Make sure the product ID matches your Play Console setup and the app is published for testing.')));
      return;
    }
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In-app purchases not available.')));
      return;
    }
    final purchaseParam = PurchaseParam(productDetails: _premiumProductDetails!);
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _showSuccessDialog(BuildContext context, String paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for upgrading to Premium.'),
            SizedBox(height: 16),
            Text('Payment Reference:'),
            SelectableText(paymentId, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  Future<void> _payWithStripe() async {
    await simulatePayment(context);
  }

  Future<void> simulatePayment(BuildContext context) async {
    // Simulate payment delay
    await Future.delayed(Duration(seconds: 2));

    // Show success popup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Payment Simulated Successfully')),
    );

    // Simulate fake payment data
    final fakePayment = {
      'paymentId': 'simulated_12345',
      'amount': 5000,
      'status': 'succeeded',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save to Firebase
    await saveSimulatedPaymentToFirebase(fakePayment);

    // Update user premium status
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumPurchasedAt': FieldValue.serverTimestamp(),
      });
    }
    setState(() {});
  }

  Future<void> saveSimulatedPaymentToFirebase(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('payments').add({
      'userId': user?.uid,
      'paymentId': data['paymentId'],
      'amount': data['amount'],
      'status': data['status'],
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremium = prefs.getBool('isPremium') ?? false;
    });
  }

  Future<void> _setPremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);
    setState(() {
      isPremium = value;
    });
  }

  Future<void> _checkIfPaidToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final payments = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    setState(() {
      _hasPaidToday = payments.docs.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Log screen view for analytics
    FirebaseAnalytics.instance.logScreenView(screenName: 'HomeScreen');
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Text(
                'SmartCare',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: theme.colorScheme.onSurface),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
              title: Text('Notifications'),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              title: Text('Settings'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.onSurface),
              title: Text('Logout'),
              onTap: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/signin', (route) => false);
                }
              },
            ),
            if (!isPremium)
              ListTile(
                leading: Icon(Icons.star, color: Colors.amber),
                title: Text('Go Premium'),
                onTap: kIsWeb
                  ? () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Upgrade to Premium'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Unlock premium features for only 5,000 RWF.'),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(Icons.payment),
                              label: Text('Pay with Stripe'),
                              onPressed: () => _payWithStripeWeb(context),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                        ],
                      ),
                    )
                  : !(Platform.isAndroid || Platform.isIOS)
                    ? () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Not Available'),
                          content: Text('In-app purchases are only available on Android and iOS.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                        ),
                      )
                    : () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Upgrade to Premium'),
                            content: _purchasePending
                              ? Center(child: CircularProgressIndicator())
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_premiumProductDetails != null
                                        ? 'Unlock premium features for only ${_premiumProductDetails!.price}.'
                                        : 'Premium product not found. Make sure the product ID matches your Play Console setup.'),
                                    SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.shopping_cart),
                                      label: Text('Buy with In-App Purchase'),
                                      onPressed: _premiumProductDetails != null ? _buyPremium : null,
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.payment),
                                      label: Text('Pay with Stripe'),
                                      onPressed: (_isPaying || _hasPaidToday) ? null : () => _payWithStripeWeb(context),
                                    ),
                                  ],
                                ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                            ],
                          ),
                        );
                      },
              ),
            if (isPremium)
              ListTile(
                leading: Icon(Icons.verified, color: Colors.amber),
                title: Text('Premium User'),
                subtitle: Text('Thank you for supporting us!'),
                onTap: null,
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'SmartCare',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      switch (value) {
                        case 'settings':
                          // _showSettingsDialog(context);
                          break;
                        case 'logout':
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/signin', (route) => false);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _buildWelcomeSection(theme),
                          const SizedBox(height: 24),
                          _buildStatsSection(theme),
                          const SizedBox(height: 24),
                          _buildQuickActionsSection(theme),
                          const SizedBox(height: 24),
                          _buildUpcomingAppointmentsSection(theme),
                          const SizedBox(height: 24),
                          _buildFeaturedDoctorsSection(theme),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_bannerAd != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
      bottomNavigationBar: null, // Removed bottom navigation bar as banner is now at the bottom
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_user?.displayName ?? _user?.email ?? 'User'}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your health is our priority',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    if (_user == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAppointmentsForUser(_user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final userAppointments = snapshot.data!.docs;
        final now = DateTime.now();
        int total = userAppointments.length;
        int approved = 0;
        int upcoming = 0;
        int completed = 0;
        int cancelled = 0;

        for (final aptDoc in userAppointments) {
          final apt = aptDoc.data() as Map<String, dynamic>;
          final status = apt['status'] ?? '';
          final dateStr = apt['date'] ?? '';
          final timeStr = apt['timeSlot'] ?? '';
          DateTime? aptDateTime;
          try {
            if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
              final dateParts = dateStr.split('-');
              final timeParts = timeStr.split(':');
              if (dateParts.length == 3 && timeParts.length >= 2) {
                aptDateTime = DateTime(
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[2]),
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );
              }
            }
          } catch (_) {}

          if (status == 'approved') {
            approved++;
            if (aptDateTime != null && aptDateTime.isAfter(now)) {
              upcoming++;
            } else if (aptDateTime != null && aptDateTime.isBefore(now)) {
              completed++;
            }
          } else if (status == 'confirmed') {
            if (aptDateTime != null && aptDateTime.isAfter(now)) {
              upcoming++;
            } else if (aptDateTime != null && aptDateTime.isBefore(now)) {
              completed++;
            }
          } else if (status == 'completed') {
            completed++;
          } else if (status == 'cancelled' || status == 'rejected') {
            cancelled++;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(theme, 'Total', total.toString(),
                  Icons.receipt_long, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                  theme, 'Approved', approved.toString(), Icons.verified, Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(theme, 'Upcoming', upcoming.toString(), Icons.event, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(theme, 'Completed', completed.toString(), Icons.check_circle, Colors.purple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(theme, 'Cancelled', cancelled.toString(), Icons.cancel, Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodyMedium),
          ],
        ));
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(theme, 'Find a Doctor', Icons.person_search,
            () => Navigator.pushNamed(context, '/doctors')),
        _buildActionItem(theme, 'My Bookings', Icons.book_online,
            () => Navigator.pushNamed(context, '/my_bookings')),
        _buildActionItem(theme, 'Hospitals', Icons.local_hospital, () {}),
      ],
    );
  }

  Widget _buildActionItem(
      ThemeData theme, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodyMedium)
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection(ThemeData theme) {
    if (_user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Appointment', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getAppointmentsForUser(_user!.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No upcoming appointments.');
            }
            final now = DateTime.now();
            final upcomingAppointments = snapshot.data!.docs.where((doc) {
              final apt = doc.data() as Map<String, dynamic>;
              final status = apt['status'] ?? '';
              final dateStr = apt['date'] ?? '';
              final timeStr = apt['timeSlot'] ?? '';
              DateTime? aptDateTime;
              try {
                if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
                  final dateParts = dateStr.split('-');
                  final timeParts = timeStr.split(':');
                  if (dateParts.length == 3 && timeParts.length >= 2) {
                    aptDateTime = DateTime(
                      int.parse(dateParts[0]),
                      int.parse(dateParts[1]),
                      int.parse(dateParts[2]),
                      int.parse(timeParts[0]),
                      int.parse(timeParts[1]),
                    );
                  }
                }
              } catch (_) {}
              return (status == 'approved' || status == 'confirmed') &&
                  aptDateTime != null && aptDateTime.isAfter(now);
            }).toList();

            if (upcomingAppointments.isEmpty) {
              return const Text('No upcoming appointments.');
            }
            final appointment =
                upcomingAppointments.first.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(appointment['doctorName'] ?? ''),
              subtitle: Text('${appointment['date']} at ${appointment['timeSlot']}'),
              trailing: Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/my_bookings'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedDoctorsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Featured Doctors', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.doctorsCollection.limit(3).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Error loading doctors');
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Text('No doctors available.');

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final doctor = doc.data() as Map<String, dynamic>;
                doctor['id'] = doc.id;
                return _buildDoctorCard(theme, doctor);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorCard(ThemeData theme, Map<String, dynamic> doctor) {
    return material.Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              NetworkImage(doctor['imageUrl'] ?? 'https://via.placeholder.com/150'),
        ),
        title: Text(doctor['name'] ?? 'Doctor Name'),
        subtitle: Text(doctor['specialty'] ?? 'Specialty'),
        trailing: Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.pushNamed(context, '/doctor_details', arguments: doctor),
      ),
    );
  }

  Future<void> _payWithStripeWeb(BuildContext context) async {
    if (_isPaying || _hasPaidToday) return;
    setState(() { _isPaying = true; });
    try {
      // Show success popup immediately
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Payment Successful!'),
          content: Text('Thank you for upgrading to Premium. Your payment is being processed.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );

      // Simulate payment delay
      await Future.delayed(Duration(seconds: 2));

      // Simulated payment data
      final fakePayment = {
        'paymentId': 'simulated_12345',
        'amount': 5000,
        'status': 'succeeded',
      };

      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in.");
        setState(() { _isPaying = false; });
        return;
      }

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'paymentId': fakePayment['paymentId'],
        'amount': fakePayment['amount'],
        'status': fakePayment['status'],
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumPurchasedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isPaying = false;
        _hasPaidToday = true;
      });

      print("✅ Simulated payment stored in Firebase!");
    } catch (e) {
      print("❌ Error: $e");
      setState(() { _isPaying = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to simulate payment')),
      );
    }
  }

  // Example: Add analytics event when booking an appointment
  void _logAppointmentBooked() {
    FirebaseAnalytics.instance.logEvent(name: 'appointment_booked');
  }
  // Example: Add analytics event when viewing a doctor profile
  void _logDoctorProfileViewed(String doctorId) {
    FirebaseAnalytics.instance.logEvent(name: 'doctor_profile_viewed', parameters: {'doctor_id': doctorId});
  }
  // Example: Add analytics event when user signs in (call this after successful sign-in)
  void _logUserSignIn(String userId) {
    FirebaseAnalytics.instance.logEvent(name: 'user_sign_in', parameters: {'user_id': userId});
  }
} 