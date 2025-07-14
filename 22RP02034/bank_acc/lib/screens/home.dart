import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'settings.dart';
import 'transaction.dart';
import 'payment.dart';
import 'card.dart';
import 'subscription.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String? userEmail;

  final List<String> pageNames = [
    'Dashboard',
    'Transaction',
    'Payment',
    'Card',
    'Subscription',
    'Settings',
  ];

  List<Widget> get pages => [
    DashboardScreen(userEmail: userEmail),
    TransactionScreen(userEmail: userEmail),
    PaymentScreen(userEmail: userEmail),
    CardScreen(userEmail: userEmail),
    SubscriptionScreen(userEmail: userEmail),
    SettingsScreen(userEmail: userEmail),
  ];

  void _onSelect(int index) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.of(context).pop(); // Close drawer if open
    // Remove special navigation for settings
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['userEmail'] != null) {
      userEmail = args['userEmail'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          // Desktop/tablet: NavigationRail
          return Scaffold(
            // No backgroundColor set here, use default
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                    // Remove special navigation for settings
                  },
                  backgroundColor: const Color(0xFF232B47),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bank El',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard, color: Colors.white),
                      selectedIcon: Icon(Icons.dashboard, color: Colors.white),
                      label: Text(
                        'Dashboard',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.swap_horiz, color: Colors.white),
                      selectedIcon: Icon(Icons.swap_horiz, color: Colors.white),
                      label: Text(
                        'Transaction',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.payment, color: Colors.white),
                      selectedIcon: Icon(Icons.payment, color: Colors.white),
                      label: Text(
                        'Payment',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.credit_card, color: Colors.white),
                      selectedIcon: Icon(
                        Icons.credit_card,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Card',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.subscriptions, color: Colors.white),
                      selectedIcon: Icon(
                        Icons.subscriptions,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Subscription',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings, color: Colors.white),
                      selectedIcon: Icon(Icons.settings, color: Colors.white),
                      label: Text(
                        'Settings',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: const IconThemeData(
                    color: Colors.white70,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.white70,
                  ),
                  minWidth: 72,
                  minExtendedWidth: 200,
                ),
                Expanded(child: pages[selectedIndex]),
              ],
            ),
          );
        } else {
          // Mobile: Drawer
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF232B47),
              title: const Text(
                'Bank El',
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xFF232B47),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bank El',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    selected: selectedIndex == 0,
                    onTap: () => _onSelect(0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Transaction'),
                    selected: selectedIndex == 1,
                    onTap: () => _onSelect(1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: const Text('Payment'),
                    selected: selectedIndex == 2,
                    onTap: () => _onSelect(2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Card'),
                    selected: selectedIndex == 3,
                    onTap: () => _onSelect(3),
                  ),
                  ListTile(
                    leading: const Icon(Icons.subscriptions),
                    title: const Text('Subscription'),
                    selected: selectedIndex == 4,
                    onTap: () => _onSelect(4),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    selected: selectedIndex == 5,
                    onTap: () => _onSelect(5),
                  ),
                ],
              ),
            ),
            body: pages[selectedIndex],
          );
        }
      },
    );
  }
}
