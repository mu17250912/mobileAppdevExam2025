import 'package:flutter/material.dart';
import '../../core/trip_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverProfileScreen extends StatefulWidget {
  static const String routeName = '/driver_profile';
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (color ?? Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color ?? Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (color ?? Colors.green).withOpacity(0.8),
              color ?? Colors.green,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.green).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewerName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      review['createdAt'] != null && review['createdAt'] is Timestamp
                          ? _formatDate((review['createdAt'] as Timestamp).toDate())
                          : 'Recent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      review['rating'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverArg = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final driverId = driverArg['id'] ?? '';
    
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: driverId.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(driverId).get()
            : null,
        builder: (context, snapshot) {
          Map<String, dynamic> driver = driverArg;
          if (snapshot.connectionState == ConnectionState.waiting && driverId.isNotEmpty) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            driver = snapshot.data!.data() as Map<String, dynamic>;
            driver['id'] = driverId;
          }
          // Check for required fields
          final hasRequiredFields = driver['name'] != null && driver['name'].toString().trim().isNotEmpty &&
              driver['driverInfo'] != null && driver['driverInfo']['carModel'] != null && driver['driverInfo']['carModel'].toString().trim().isNotEmpty;
          if (!hasRequiredFields) {
            return Center(
              child: Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.warning, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('Driver profile is incomplete. Cannot request a ride from this driver.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return Stack(
            children: [
              // Background gradient
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              
              // Content
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.green.shade600,
                    elevation: 0,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                // Profile picture with border
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(
                                      driver['photo'] ?? 'https://randomuser.me/api/portraits/men/32.jpg',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  driver['name'] ?? 'Unknown Driver',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    driver['driverInfo']?['carModel'] ?? 'Professional Driver',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          // Rating section
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('rideRequests')
                                  .where('driverId', isEqualTo: driverId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collectionGroup('reviews')
                                      .where('driverId', isEqualTo: driverId)
                                      .get(),
                                  builder: (context, reviewSnap) {
                                    if (!reviewSnap.hasData) {
                                      return const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star_border, color: Colors.amber, size: 24),
                                          SizedBox(width: 8),
                                          Text('No ratings yet', style: TextStyle(fontSize: 16)),
                                        ],
                                      );
                                    }
                                    
                                    final reviews = reviewSnap.data!.docs;
                                    if (reviews.isEmpty) {
                                      return const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.star_border, color: Colors.amber, size: 24),
                                          SizedBox(width: 8),
                                          Text('No ratings yet', style: TextStyle(fontSize: 16)),
                                        ],
                                      );
                                    }
                                    
                                    final avg = reviews.map((r) => (r['rating'] as num).toDouble())
                                        .reduce((a, b) => a + b) / reviews.length;
                                    
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ...List.generate(5, (index) {
                                          return Icon(
                                            index < avg.round() ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 24,
                                          );
                                        }),
                                        const SizedBox(width: 12),
                                        Text(
                                          avg.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          ' (${reviews.length} reviews)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          
                          // Driver info cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildInfoCard(
                                  title: 'License Number',
                                  value: driver['driverInfo']?['license'] ?? 'Not provided',
                                  icon: Icons.credit_card,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  title: 'Contact',
                                  value: driver['contact'] ?? 'Not provided',
                                  icon: Icons.phone,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          // Removed placeholder call and chat buttons
                          // Only show the real WhatsApp chat button below
                          
                          const SizedBox(height: 24),
                          
                          // WhatsApp chat button
                          if (driver['contact'] != null && driver['contact'].toString().isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final phone = driver['whatsapp'] ?? driver['contact'];
                                final url = 'https://wa.me/$phone';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp.')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text('Chat on WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Bio section
                          if (driver['bio'] != null && driver['bio'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    driver['bio'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Request ride button
                          Container(
                            margin: const EdgeInsets.all(16),
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading 
                                    ? [Colors.grey.shade400, Colors.grey.shade500]
                                    : [Colors.green.shade400, Colors.green.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isLoading ? Colors.grey : Colors.green).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _requestRide(context, driver, driverId),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.local_taxi, color: Colors.white),
                              label: Text(
                                _isLoading ? 'Sending Request...' : 'Request Ride',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _requestRide(BuildContext context, Map<String, dynamic> driver, String driverId) async {
    final pickupController = TextEditingController();
    final dropoffController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Request Ride',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pickupController,
                decoration: InputDecoration(
                  labelText: 'Pickup Location',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dropoffController,
                decoration: InputDecoration(
                  labelText: 'Drop-off Location',
                  prefixIcon: const Icon(Icons.flag, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'pickup': pickupController.text,
                'dropoff': dropoffController.text,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    
    if (result != null && result['pickup']!.isNotEmpty && result['dropoff']!.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        // Fetch passenger info
        final user = FirebaseAuth.instance.currentUser;
        String passengerName = '';
        String passengerContact = '';
        
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final data = doc.data();
          if (data != null) {
            passengerName = data['name'] ?? user.displayName ?? user.email ?? '';
            passengerContact = data['contact'] ?? user.email ?? '';
          } else {
            passengerName = user.displayName ?? user.email ?? '';
            passengerContact = user.email ?? '';
          }
        }
        
        await TripManager.addRideRequest({
          'pickup': result['pickup'],
          'dropoff': result['dropoff'],
          'fare': 2500,
          'driverId': driverId,
          'driverName': driver['name'] ?? '',
          'car': driver['driverInfo']?['carModel'] ?? '',
          'photo': driver['photo'] ?? '',
          'date': DateTime.now().toString().substring(0, 10),
          'time': TimeOfDay.now().format(context),
          'passengerName': passengerName,
          'passengerContact': passengerContact,
        });
        
        setState(() => _isLoading = false);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text('Request Sent'),
                ],
              ),
              content: Text(
                'Your ride request has been sent to ${driver['name'] ?? 'the driver'}. You will be notified when they accept.',
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}