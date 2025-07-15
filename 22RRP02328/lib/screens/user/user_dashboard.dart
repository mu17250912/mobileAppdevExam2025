import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faith/providers/auth_provider.dart' as my_auth;
import '../../providers/user_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../utils/constants.dart';
import '../booking/booking_form.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../messaging/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  void _showStartChatDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<my_auth.AuthProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final providers = Provider.of<UserProvider>(context, listen: false).serviceProviders;
          return AlertDialog(
            title: Text('Start New Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'U'),
                    ),
                    title: Text(provider.name),
                    subtitle: Text(provider.email),
                    onTap: () async {
                      Navigator.pop(context);
                      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
                      await messagingProvider.startNewChat(provider.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Started chat with ${provider.name}')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await userProvider.loadUserData(authProvider.currentUser!.uid);
      await eventProvider.loadUserEvents(authProvider.currentUser!.uid);
      await userProvider.loadServiceProviders();
      messagingProvider.initialize();
      subscriptionProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildEventsTab(),
          _buildServicesTab(),
          _buildMessagesTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/LOGO.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Faith',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Center(
                child: Text(
                  'My Events',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Get.toNamed('/notifications');
            },
          ),
          Consumer<my_auth.AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.userData;
              return GestureDetector(
                onTap: () {
                  // Go to profile tab or open profile screen
                  setState(() {
                    _currentIndex = 4; // Profile tab index
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(AppColors.primaryColor),
                    backgroundImage: (user?.profileImage != null && user?.profileImage?.isNotEmpty == true)
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    child: (user?.profileImage == null || user?.profileImage?.isEmpty == true)
                        ? Text(
                            (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<my_auth.AuthProvider>(
              builder: (context, authProvider, child) {
                final userName = authProvider.userData?.name ?? 'User';
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(AppColors.primaryColor),
                        Color(AppColors.secondaryColor),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 4; // Profile tab index
                          });
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(AppColors.primaryColor),
                          backgroundImage: (authProvider.userData?.profileImage != null && authProvider.userData?.profileImage?.isNotEmpty == true)
                              ? NetworkImage(authProvider.userData!.profileImage!)
                              : null,
                          child: (authProvider.userData?.profileImage == null || authProvider.userData?.profileImage?.isEmpty == true)
                              ? Text(
                                  (authProvider.userData?.name.isNotEmpty == true ? authProvider.userData!.name[0].toUpperCase() : 'U'),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, $userName!',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to plan your next amazing event?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
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
            
            const SizedBox(height: 24),
            
            // Subscription Status
            Consumer<SubscriptionProvider>(
              builder: (context, subscriptionProvider, child) {
                final currentSubscription = subscriptionProvider.currentSubscription;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentSubscription?.isPremium == true 
                        ? const Color(AppColors.successColor).withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentSubscription?.isPremium == true 
                          ? const Color(AppColors.successColor)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentSubscription?.isPremium == true 
                            ? Icons.verified
                            : Icons.info_outline,
                        color: currentSubscription?.isPremium == true 
                            ? const Color(AppColors.successColor)
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSubscription?.isPremium == true 
                                  ? 'Premium Subscription Active'
                                  : 'Free Plan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: currentSubscription?.isPremium == true 
                                    ? const Color(AppColors.successColor)
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentSubscription?.isPremium == true 
                                  ? 'Enjoy all premium features'
                                  : 'Upgrade to unlock premium features',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentSubscription?.isPremium != true)
                        TextButton(
                          onPressed: () {
                            Get.toNamed('/subscription-plans');
                          },
                          child: Text(
                            'Upgrade',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(AppColors.primaryColor),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.add_circle,
                    title: 'Create Event',
                    subtitle: 'Plan a new event',
                    onTap: () {
                      Get.toNamed('/create-event');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.search,
                    title: 'Find Services',
                    subtitle: 'Browse service providers',
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Services tab
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.subscriptions,
                    title: 'Subscription',
                    subtitle: 'Manage premium features',
                    onTap: () {
                      Get.toNamed('/subscription-details');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.payment,
                    title: 'Payments',
                    subtitle: 'View payment history',
                    onTap: () {
                      Get.toNamed('/payment-history');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.history,
                    title: 'Booking History',
                    subtitle: 'View your bookings',
                    onTap: () {
                      Get.toNamed('/booking-history');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.payment,
                    title: 'Payments',
                    subtitle: 'View payment history',
                    onTap: () {
                      Get.toNamed('/payment-history');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Events
            Text(
              'Recent Events',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventProvider.events.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first event to get started',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                // Sort events by createdAt descending
                final recentEvents = [...eventProvider.events];
                recentEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  children: recentEvents.take(3).map((event) {
                    return _buildEventCard(event);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed('/create-event');
            },
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          if (eventProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (eventProvider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first event to get started',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Get.toNamed('/create-event');
                    },
                    child: const Text('Create Event'),
                  ),
                ],
              ),
            );
          }
          // Sort events by createdAt descending
          final allEvents = [...eventProvider.events];
          allEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allEvents.length,
            itemBuilder: (context, index) {
              final event = allEvents[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
    );
  }

  Widget _buildServicesTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userProvider.serviceProviders.length,
            itemBuilder: (context, index) {
              final provider = userProvider.serviceProviders[index];
              return _buildServiceProviderCard(provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Consumer<MessagingProvider>(
            builder: (context, messagingProvider, child) {
              if (messagingProvider.unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(AppColors.errorColor),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    messagingProvider.unreadCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, messagingProvider, child) {
          if (messagingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messagingProvider.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new chat to connect with others!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Start chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _showStartChatDialog();
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messagingProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = messagingProvider.chats[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chat.id),
                    ),
                  );
                },
                child: _buildChatCard(chat, messagingProvider),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showStartChatDialog,
        child: const Icon(Icons.add),
        tooltip: 'Start New Chat',
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<my_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userData;
          return Column(
            children: [
              GestureDetector(
                onTap: () => _showEditProfileDialog(authProvider),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickProfileImage(authProvider),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(AppColors.primaryColor),
                          backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: (user?.profileImage == null || user!.profileImage!.isEmpty)
                              ? Text(
                                  (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U'),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 32),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name?.toUpperCase() ?? 'USER',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to edit profile',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
              _buildProfileOption(
                icon: Icons.edit,
                title: 'Edit Profile',
                onTap: () => _showEditProfileDialog(authProvider),
              ),
              _buildProfileOption(
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help & Support'),
                      content: const Text('For support, email us at ramcode@gmail.com.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Close'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'ramcode@gmail.com',
                              query: Uri.encodeFull('subject=Support Request&body=Hello, I need help with...'),
                            );
                            // Use url_launcher to open the email client
                            // You must add url_launcher to pubspec.yaml
                            // import 'package:url_launcher/url_launcher.dart';
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            }
                          },
                          child: const Text('Write Message'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () => _showLogoutDialog(authProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfileDialog(my_auth.AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.userData?.name ?? '');
    final emailController = TextEditingController(text: authProvider.userData?.email ?? '');
    final passwordController = TextEditingController();
    String? newProfileImage = authProvider.userData?.profileImage;

    Future<void> pickNewProfileImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${authProvider.currentUser?.uid}.jpg');
        await storageRef.putData(await pickedFile.readAsBytes());
        final url = await storageRef.getDownloadURL();
        newProfileImage = url;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  await pickNewProfileImage();
                  setState(() {});
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(AppColors.primaryColor),
                  backgroundImage: (newProfileImage != null && newProfileImage?.isNotEmpty == true)
                      ? NetworkImage(newProfileImage!)
                      : null,
                  child: (newProfileImage == null || newProfileImage?.isEmpty == true)
                      ? Text(
                          (authProvider.userData?.name.isNotEmpty == true ? authProvider.userData!.name[0].toUpperCase() : 'U'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newPassword = passwordController.text.trim();
                Map<String, dynamic> updateData = {};
                if (newName.isNotEmpty) updateData['name'] = newName;
                if (newProfileImage != null && newProfileImage?.isNotEmpty == true) updateData['profileImage'] = newProfileImage;
                if (updateData.isNotEmpty) {
                  await authProvider.updateUserProfile(updateData);
                }
                if (newPassword.isNotEmpty) {
                  // Change password via Firebase Auth
                  try {
                    await authProvider.currentUser?.updatePassword(newPassword);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update password: $e')),
                    );
                  }
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(my_auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.signOut(context);
              // Do NOT call Navigator.pop(context) here!
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(my_auth.AuthProvider authProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${authProvider.currentUser?.uid}.jpg');
      await storageRef.putData(await pickedFile.readAsBytes());
      final url = await storageRef.getDownloadURL();
      await authProvider.updateUserProfile({'profileImage': url});
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    }
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(AppColors.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              event.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (event.status == 'confirmed')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppColors.successColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CONFIRMED',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              event.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(event.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.status.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to event details
        },
      ),
    );
  }

  Widget _buildServiceProviderCard(UserModel provider) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    final userEvents = eventProvider.events.where((event) => event.organizerId == authProvider.currentUser?.uid).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(AppColors.primaryColor),
          child: Text(
            provider.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          provider.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              provider.bio ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${provider.rating} (${provider.reviewCount} reviews)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BookingForm(provider: provider, userEvents: userEvents),
            );
          },
          child: const Text('Book'),
        ),
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat, MessagingProvider messagingProvider) {
    final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;
    final otherParticipantName = messagingProvider.getOtherParticipantName(chat.id);
    final unreadCount = currentUserId != null ? (chat.unreadCounts[currentUserId] ?? 0) : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(AppColors.primaryColor),
          child: Text(
            otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : 'U',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          otherParticipantName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage.isNotEmpty 
                  ? chat.lastMessage 
                  : 'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(chat.lastMessageTime),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(AppColors.primaryColor),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        onTap: () {
          // TODO: Navigate to chat screen
        },
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(AppColors.primaryColor)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.bookingConfirmed:
        return const Color(AppColors.successColor);
      case AppConstants.bookingPending:
        return const Color(AppColors.warningColor);
      case AppConstants.bookingCancelled:
        return const Color(AppColors.errorColor);
      default:
        return Colors.grey;
    }
  }
}

class _SettingsScreen extends StatefulWidget {
  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notifications = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _darkMode = value);
    // TODO: Actually apply theme change in the app (requires app-level state management)
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notifications = value);
    // TODO: Actually enable/disable notifications in the app
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              if (currentPassword.isEmpty || newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields.')),
                );
                return;
              }
              try {
                final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                if (user == null || user.email == null) throw 'User not found.';
                final providerId = user.providerData.isNotEmpty ? user.providerData[0].providerId : 'password';
                if (providerId == 'password') {
                  final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
                  await user.reauthenticateWithCredential(cred);
                } else if (providerId == 'google.com') {
                  final googleUser = await GoogleSignIn().signIn();
                  if (googleUser == null) throw 'Google sign-in aborted.';
                  final googleAuth = await googleUser.authentication;
                  final googleCred = GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );
                  await user.reauthenticateWithCredential(googleCred);
                } else {
                  throw 'Unsupported sign-in provider.';
                }
                await user.updatePassword(newPassword);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update password: $e')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                if (user == null) throw 'User not found.';
                await user.delete();
                await authProvider.signOut(context);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete account: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: _setNotifications,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Account'),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
} 