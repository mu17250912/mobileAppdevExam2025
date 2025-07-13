import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'tabs/events_tab.dart';
import 'tabs/my_events_tab.dart';
import 'tabs/profile_tab.dart';
import '../../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const EventsTab(),
    const MyEventsTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    
    if (authProvider.firebaseUser != null) {
      eventProvider.loadMyEvents(authProvider.firebaseUser!.uid);
      eventProvider.loadParticipatingEvents(authProvider.firebaseUser!.uid);
    }
  }

  void _refreshUserData() {
    _loadUserData();
  }

  void _showPremiumUpgradeDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              const Text('Upgrade to Premium'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unlock premium features and enjoy an ad-free experience!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...AppConstants.premiumFeatures.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.accentColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly: \$4.99 | Yearly: \$39.99',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Simulate payment and upgrade
                final userId = authProvider.firebaseUser?.uid;
                if (userId != null) {
                  await authProvider.updateProfile({'isPremium': true});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('You are now a Premium user!'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment'),
          content: const Text(
            'Payment integration will be implemented here. For now, this is a demo showing the premium upgrade flow.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Premium upgrade feature coming soon!'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Demo Upgrade'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              // Top bar with premium and sign out buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (authProvider.userModel?.isPremium ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _showPremiumUpgradeDialog(context),
                        icon: const Icon(Icons.star),
                        label: const Text('Upgrade to Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _tabs[_currentIndex]),
              const BannerAdWidget(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_library_books),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                context.push('/create-event').then((_) {
                  _refreshUserData();
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 