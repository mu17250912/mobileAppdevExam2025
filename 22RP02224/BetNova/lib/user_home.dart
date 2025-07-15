import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:bet_nova/models.dart';
import 'firestore_service.dart';
import 'user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'betslip_provider.dart';
import 'package:intl/intl.dart';
import 'auth_screen.dart';
import 'firebase_search_delegate.dart';
import 'my_bet_slip_widget.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'subscription_service.dart';
import 'premium_subscription_screen.dart';
import 'ad_service.dart';
import 'dart:async';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedSportsTab = 0; // 0: Upcoming, 1: Popular, 2: Live Now, 3: Boosted
  final List<String> _sportsTabs = ['Upcoming', 'Popular', 'Live Now', 'Boosted'];
  String _selectedLeague = 'All Markets';
  String _selectedMarket = 'All Markets';
  double? _userBalance;
  final List<String> _popularSports = ['Football', 'Basketball', 'Volleyball'];

  // Add icons for sports
  final Map<String, IconData> _sportIcons = {
    'Football': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Volleyball': Icons.sports_volleyball,
  };

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.sports},
    {'label': 'Live Now', 'icon': Icons.flash_on},
    {'label': 'Boosted', 'icon': Icons.trending_up},
    {'label': 'FIFA Club WC', 'icon': Icons.sports_soccer},
    {'label': 'Premier League', 'icon': Icons.emoji_events},
  ];

  // Add state for selected menu sport, country, and champion
  String _menuSelectedSport = 'Football';
  Country? _menuSelectedCountry;
  Champion? _menuSelectedChampion;
  List<Country> _menuCountries = [];
  List<Champion> _menuChampions = [];
  bool _isLoadingMenuCountries = true;
  bool _isLoadingMenuChampions = false;

  // Add state for all countries section
  List<Country> _allMenuCountries = [];
  List<Champion> _allMenuChampions = [];
  Country? _allMenuSelectedCountry;
  Champion? _allMenuSelectedChampion;
  bool _isLoadingAllMenuCountries = true;
  bool _isLoadingAllMenuChampions = false;

  // Bottom navigation state
  int _currentBottomNavIndex = 0;

  // 1. Add state for selected date and market at the top of _UserHomeScreenState:
  DateTime? _selectedDate;

  // Add this near the top of your state class:
  final List<Color> _tabColors = [
    Colors.green,    // Upcoming
    Colors.purple,   // Popular
    Colors.orange,   // Live Now
    Colors.blue,     // Boosted
  ];

  final Map<String, String> _selectedOdds = {}; // matchId -> selected odd key

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
    _fetchMenuCountriesForSport(_menuSelectedSport);
    _fetchAllMenuCountries();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchUserBalance() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('balance')) {
        setState(() {
          _userBalance = (doc['balance'] as num?)?.toDouble() ?? 0.0;
        });
      }
    }
  }





  void _showDepositModal() {
    showDialog(
      context: context,
      builder: (context) => _DepositDialog(
        onDeposit: (amount) async {
          // Simulate deposit: update user balance in Firestore
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final current = (doc['balance'] as num?)?.toDouble() ?? 0.0;
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'balance': current + amount});
            _fetchUserBalance();
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0: // Home
        // Already on home, do nothing
        break;
      case 1: // Sports
        _showSportsNavigation();
        break;
      case 2: // My Bets
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const MyBetSlipWidget(),
        );
        break;
      case 3: // Account
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfile()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[900],
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sports selection (vertical)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SPORTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        ..._popularSports.map((sport) {
                          final selected = _menuSelectedSport == sport;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                _menuSelectedSport = sport;
                                _menuSelectedCountry = null;
                                _menuSelectedChampion = null;
                              });
                              _fetchMenuCountriesForSport(sport);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? Colors.green[100] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? Colors.green : Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(_sportIcons[sport], color: selected ? Colors.green[900] : Colors.green[400]),
                                  const SizedBox(width: 10),
                                  Text(sport, style: TextStyle(color: Colors.green[900], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Countries (vertical, scrollable)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('COUNTRIES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  _isLoadingMenuCountries
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: 120,
                        child: ListView.builder(
                          itemCount: _menuCountries.length,
                          itemBuilder: (context, idx) {
                            final country = _menuCountries[idx];
                            final selected = _menuSelectedCountry?.id == country.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _menuSelectedCountry = country;
                                  _menuSelectedChampion = null;
                                });
                                _fetchMenuChampionsForCountry(country, _menuSelectedSport);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.green[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: selected ? Colors.green : Colors.grey[200]!),
                                ),
                                child: Text(country.name, style: TextStyle(color: Colors.green[900], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ),
                            );
                          },
                        ),
                      ),
                  const Divider(),
                  // Champions for selected country
                  if (_menuSelectedCountry != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('CHAMPIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  if (_menuSelectedCountry != null)
                    _isLoadingMenuChampions
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            itemCount: _menuChampions.length,
                            itemBuilder: (context, idx) {
                              final champion = _menuChampions[idx];
                              final selected = _menuSelectedChampion?.id == champion.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _menuSelectedChampion = champion;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.green[100] : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: selected ? Colors.green : Colors.grey[200]!),
                                  ),
                                  child: Text(champion.name, style: TextStyle(color: Colors.green[900], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                ),
                              );
                            },
                          ),
                        ),
                  const Divider(),
                  // All Countries Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('ALL COUNTRIES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  _isLoadingAllMenuCountries
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _allMenuCountries.length,
                          itemBuilder: (context, idx) {
                            final country = _allMenuCountries[idx];
                            final selected = _allMenuSelectedCountry?.id == country.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _allMenuSelectedCountry = country;
                                  _allMenuSelectedChampion = null;
                                });
                                _fetchAllMenuChampionsForCountry(country);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.green[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: selected ? Colors.green : Colors.grey[200]!),
                                ),
                                child: Text(country.name, style: TextStyle(color: Colors.green[900], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ),
                            );
                          },
                        ),
                      ),
                  const Divider(),
                  // All Champions for selected country
                  if (_allMenuSelectedCountry != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('ALL CHAMPIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  if (_allMenuSelectedCountry != null)
                    _isLoadingAllMenuChampions
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            itemCount: _allMenuChampions.length,
                            itemBuilder: (context, idx) {
                              final champion = _allMenuChampions[idx];
                              final selected = _allMenuSelectedChampion?.id == champion.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _allMenuSelectedChampion = champion;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.green[100] : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: selected ? Colors.green : Colors.grey[200]!),
                                  ),
                                  child: Text(champion.name, style: TextStyle(color: Colors.green[900], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Premium subscription option
                  FutureBuilder<User?>(
                    future: SubscriptionService.getCurrentUser(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final isPremium = user?.hasActiveSubscription ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPremium 
                                    ? [Colors.amber.shade400, Colors.amber.shade600]
                                    : [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPremium ? Icons.star : Icons.star_border,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPremium ? 'Premium Active' : 'Upgrade to Premium',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isPremium 
                                            ? 'All premium features unlocked'
                                            : 'Unlock exclusive features',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.green),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'BetNova',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FirebaseSearchDelegate(),
              );
            },
          ),
          if (_userBalance != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  '${_userBalance!.toStringAsFixed(2)} RWF',
                  style: const TextStyle(
                    color: Colors.lime,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          if (_userBalance != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _showDepositModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  elevation: 0,
                ),
                child: const Text('DEPOSIT'),
              ),
            ),
          // Premium indicator
          FutureBuilder<User?>(
            future: SubscriptionService.getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.hasActiveSubscription) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (_userBalance == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  elevation: 0,
                ),
                child: const Text('Login'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  elevation: 0,
                ),
                child: const Text('Join Now'),
              ),
            ),
          ],
        ],
        backgroundColor: Colors.black,
        foregroundColor: Colors.lime,
        elevation: 1,
      ),
      // Beautiful background for the whole screen
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.lime[50]!, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navigation Tabs with dark background
              Container(
                color: Colors.grey[850],
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_sportsTabs.length, (i) {
                    final selected = _selectedSportsTab == i;
                    final tabColor = _tabColors[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSportsTab = i;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? tabColor.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _sportsTabs[i],
                          style: TextStyle(
                            color: selected ? tabColor : Colors.grey[300],
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Ad banner for free users
              AdService.buildAdBanner(context),
              // Market/Filter Row with dark background
              Container(
                color: Colors.grey[850],
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.lime, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedLeague,
                        isExpanded: true,
                        dropdownColor: Colors.grey[900],
                        underline: Container(
                          height: 1,
                          color: Colors.lime,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.lime),
                        style: const TextStyle(color: Colors.lime, fontWeight: FontWeight.w500),
                        items: [
                          'All Markets',
                          ..._categories
                              .map((c) => c['label'] as String)
                              .where((label) => label != 'All')
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedLeague = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedMarket,
                        isExpanded: true,
                        dropdownColor: Colors.grey[900],
                        underline: Container(
                          height: 1,
                          color: Colors.lime,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.lime),
                        style: const TextStyle(color: Colors.lime, fontWeight: FontWeight.w500),
                        items: <String>['All Markets', '1X2', 'Over/Under', 'Both Teams to Score']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedMarket = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.lime),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.lime, size: 20),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        tooltip: 'Select Date',
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              _buildMainContent(),
              const SizedBox(height: 32),
              // Banner Slideshow
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ads_banners').orderBy('uploadedAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                  }
                  final bannerUrls = snapshot.data!.docs.map((doc) => doc['imageUrl'] as String).toList();
                  if (bannerUrls.isEmpty) {
                    return const SizedBox(height: 160, child: Center(child: Text('No banners yet')));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 160,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        enlargeCenterPage: true,
                        viewportFraction: 1.0,
                        aspectRatio: 16 / 6,
                      ),
                      items: bannerUrls.map((url) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar with dark background
      bottomNavigationBar: Container(
        color: Colors.black,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.lime,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
            _handleBottomNavTap(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer),
              label: 'Sports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'My Bets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }





  Future<void> _fetchMenuCountriesForSport(String sport) async {
    setState(() { _isLoadingMenuCountries = true; _menuCountries = []; _menuSelectedCountry = null; _menuChampions = []; _menuSelectedChampion = null; });
    // Get all countries that have at least one champion for this sport
    final allCountries = await _firestoreService.getCountries().first;
    final allChampions = await _firestoreService.getChampions().first;
    final countryIdsWithSport = allChampions.where((c) => c.sport == sport).map((c) => c.countryId).toSet();
    final filteredCountries = allCountries.where((c) => countryIdsWithSport.contains(c.id)).toList();
    setState(() {
      _menuCountries = filteredCountries;
      _isLoadingMenuCountries = false;
    });
  }

  Future<void> _fetchMenuChampionsForCountry(Country country, String sport) async {
    setState(() { _isLoadingMenuChampions = true; _menuChampions = []; _menuSelectedChampion = null; });
    final champions = await _firestoreService.getChampionsByCountryAndSport(country.id, sport).first;
    setState(() {
      _menuChampions = champions;
      _isLoadingMenuChampions = false;
    });
  }

  Future<void> _fetchAllMenuCountries() async {
    setState(() { _isLoadingAllMenuCountries = true; });
    final countries = await _firestoreService.getCountries().first;
    setState(() {
      _allMenuCountries = countries;
      _isLoadingAllMenuCountries = false;
    });
  }

  Future<void> _fetchAllMenuChampionsForCountry(Country country) async {
    setState(() { _isLoadingAllMenuChampions = true; _allMenuChampions = []; _allMenuSelectedChampion = null; });
    
    try {
      // Use the robust method that tries both countryId and countryName
      final champions = await _firestoreService.getChampionsByCountryRobust(country.id, country.name);
      
      setState(() {
        _allMenuChampions = champions;
        _isLoadingAllMenuChampions = false;
      });
    } catch (e) {
      setState(() {
        _allMenuChampions = [];
        _isLoadingAllMenuChampions = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading champions for ${country.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildMainContent() {
    // If both country and champion are selected, show matches for both (centered)
    if (_menuSelectedCountry != null && _menuSelectedChampion != null) {
      return _buildMatchesList();
    } else if (_menuSelectedChampion != null) {
      // fallback: show matches for champion only
      return _buildMatchesList();
    } else if (_allMenuSelectedChampion != null) {
      // fallback: show matches for all champion only
      return _buildMatchesList();
    } else {
      // Show matches by default
      return _buildMatchesList();
    }
  }

  Widget _buildTeamsList(String championId) {
    return FutureBuilder<List<Team>>(
      future: _firestoreService.getTeamsByChampion(championId).first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No teams found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'This champion has no teams yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Champion ID: $championId',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }
        final teams = snapshot.data!;
        
        // Group teams by country for better organization
        final teamsByCountry = <String, List<Team>>{};
        for (final team in teams) {
          teamsByCountry.putIfAbsent(team.countryId, () => []).add(team);
        }

        return Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              // Navigation Summary
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 Teams Navigation:',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${teams.length} teams in ${teamsByCountry.length} countries',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.grey[400], size: 18),
                      onPressed: () => _showTeamNavigationHelp(),
                      tooltip: 'Navigation Help',
                    ),
                  ],
                ),
              ),

              // Teams organized by country
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: teamsByCountry.length,
                  itemBuilder: (context, index) {
                    final countryId = teamsByCountry.keys.elementAt(index);
                    final countryTeams = teamsByCountry[countryId]!;
                    
                    return FutureBuilder<Country?>(
                      future: _firestoreService.getCountry(countryId),
                      builder: (context, countrySnapshot) {
                        final countryName = countrySnapshot.data?.name ?? 'Unknown Country';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Icon(Icons.flag, color: Colors.green[700], size: 20),
                            ),
                            title: Text(
                              '🏳️ $countryName',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${countryTeams.length} teams • Tap to expand',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: countryTeams.length,
                                itemBuilder: (context, teamIndex) {
                                  final team = countryTeams[teamIndex];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      _showTeamDetails(team, countryName);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            team.logoUrl != null
                                                ? CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage: NetworkImage(team.logoUrl!),
                                                    onBackgroundImageError: (_, __) {},
                                                    backgroundColor: Colors.grey[200],
                                                  )
                                                : CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor: Colors.green[100],
                                                    child: Icon(
                                                      _getSportIcon(team.sport),
                                                      color: Colors.green[700],
                                                      size: 20,
                                                    ),
                                                  ),
                                            const SizedBox(height: 6),
                                            Flexible(
                                              child: Text(
                                                team.name,
                                                style: TextStyle(
                                                  color: Colors.green[900],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              team.sport,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport) {
      case 'Football':
        return Icons.sports_soccer;
      case 'Basketball':
        return Icons.sports_basketball;
      case 'Volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  void _showTeamDetails(Team team, String countryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            team.logoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(team.logoUrl!),
                    onBackgroundImageError: (_, __) {},
                  )
                : CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(_getSportIcon(team.sport), color: Colors.green[700]),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏳️ Country: $countryName'),
            Text('⚽ Sport: ${team.sport}'),
            if (team.logoUrl != null) const Text('🖼️ Has Logo: Yes'),
            const SizedBox(height: 16),
            Text(
              'This team is available for betting. Select matches involving this team to place bets.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you could navigate to matches for this team
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Looking for matches with ${team.name}...')),
              );
            },
            child: const Text('Find Matches'),
          ),
        ],
      ),
    );
  }

  void _showTeamNavigationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Team Navigation Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 How to navigate teams:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
            const SizedBox(height: 8),
            const Text('• Teams are organized by country'),
            const Text('• Tap country cards to expand/collapse teams'),
            const Text('• Tap team cards to see details'),
            const Text('• Use filters above to narrow down selection'),
            const SizedBox(height: 8),
            Text('🎯 Navigation Tips:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
            const SizedBox(height: 8),
            const Text('• Start with sport selection'),
            const Text('• Choose country to narrow down'),
            const Text('• Select league/championship'),
            const Text('• Browse teams by country'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showNavigationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Navigation Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 How to navigate:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
            const SizedBox(height: 8),
            const Text('• Use the breadcrumb above to go back'),
            const Text('• Tap sport/country/league to navigate'),
            const Text('• Use the side menu for quick access'),
            const SizedBox(height: 8),
            Text('🎯 Navigation Path:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
            const SizedBox(height: 8),
            const Text('Sport → Country → League → Teams/Matches'),
            const SizedBox(height: 8),
            Text('💡 Tips:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
            const SizedBox(height: 8),
            const Text('• Start broad, then narrow down'),
            const Text('• Use filters to find what you want'),
            const Text('• Teams are grouped by country'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    Stream<List<Match>> matchStream;
    // Use navigation tab selection for filtering
    switch (_selectedSportsTab) {
      case 1: // Popular
        matchStream = _firestoreService.getTrendingMatches();
        break;
      case 2: // Live Now
        matchStream = _firestoreService.getLiveMatches();
        break;
      case 3: // Boosted
        matchStream = _firestoreService.getMatchesByCategory('Boosted');
        break;
      default: // Upcoming
        matchStream = _firestoreService.getUpcomingMatches();
    }
    // Apply date and market filtering in Dart
    return StreamBuilder<List<Match>>(
      stream: matchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No matches found.'));
        }
        var matches = snapshot.data!;
        // Filter by selected date
        if (_selectedDate != null) {
          final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
          final end = start.add(const Duration(days: 1));
          matches = matches.where((m) => m.dateTimeStart.isAfter(start.subtract(const Duration(seconds: 1))) && m.dateTimeStart.isBefore(end)).toList();
        }
        // Filter by selected market
        if (_selectedMarket != 'All Markets') {
          matches = matches.where((m) => m.odds.keys.contains(_selectedMarket) || m.odds.keys.contains(_selectedMarket.toLowerCase().replaceAll(' ', '_'))).toList();
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            _autoUpdateMatchStatus(match);
            final oddsMap = match.odds;
            final has1X2 = oddsMap.containsKey('1X2');
            final hasMatchWinner = oddsMap.containsKey('match_winner');
            final mainMarketKey = has1X2 ? '1X2' : (hasMatchWinner ? 'match_winner' : null);
            final moreMarkets = oddsMap.keys.where((k) => k != mainMarketKey).toList();

            // Extract odds as strings for safe checks (use correct Firestore keys)
            final homeOdd = oddsMap[mainMarketKey]?['Home']?.toString();
            final drawOdd = oddsMap[mainMarketKey]?['Draw']?.toString();
            final awayOdd = oddsMap[mainMarketKey]?['Away']?.toString();

            // Debug print to check odds data
            print('Match: ${match.teamA} vs ${match.teamB}, odds: ${oddsMap[mainMarketKey]}');

            // Colors for selected/unselected odds buttons
            const selectedColor = Colors.lime;
            const selectedTextColor = Colors.white;
            const unselectedTextColor = Colors.green;
            const unselectedBgColor = Colors.white;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.green[100]!, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [Colors.green[50]!, Colors.lime[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('h:mm a EEE dd/MM').format(match.dateTimeStart),
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (match.status == 'live')
                      LiveMatchTimer(startTime: match.dateTimeStart, isLive: true),
                    const SizedBox(height: 6),
                    Text(
                      match.teamA,
                      style: TextStyle(
                        color: Colors.purple[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      match.teamB,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${match.category} / ${match.sport}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_selectedOdds[match.id] == 'Home') ? selectedColor : unselectedBgColor,
                              foregroundColor: (_selectedOdds[match.id] == 'Home') ? selectedTextColor : unselectedTextColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: (_selectedOdds[match.id] == 'Home') ? 4 : 1,
                              side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedOdds[match.id] = 'Home';
                              });
                              final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                              betSlip.addOrUpdateSelection(BetSelection(
                                matchId: match.id,
                                matchTitle: '${match.teamA} vs ${match.teamB}',
                                market: mainMarketKey ?? '',
                                oddKey: 'Home',
                                oddValue: double.tryParse((oddsMap[mainMarketKey]?['Home']?.toString() ?? '0')) ?? 0.0,
                              ));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                                Text(homeOdd ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_selectedOdds[match.id] == 'Draw') ? selectedColor : unselectedBgColor,
                              foregroundColor: (_selectedOdds[match.id] == 'Draw') ? selectedTextColor : unselectedTextColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: (_selectedOdds[match.id] == 'Draw') ? 4 : 1,
                              side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedOdds[match.id] = 'Draw';
                              });
                              final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                              betSlip.addOrUpdateSelection(BetSelection(
                                matchId: match.id,
                                matchTitle: '${match.teamA} vs ${match.teamB}',
                                market: mainMarketKey ?? '',
                                oddKey: 'Draw',
                                oddValue: double.tryParse((oddsMap[mainMarketKey]?['Draw']?.toString() ?? '0')) ?? 0.0,
                              ));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('X', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                                Text(drawOdd ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_selectedOdds[match.id] == 'Away') ? selectedColor : unselectedBgColor,
                              foregroundColor: (_selectedOdds[match.id] == 'Away') ? selectedTextColor : unselectedTextColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: (_selectedOdds[match.id] == 'Away') ? 4 : 1,
                              side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedOdds[match.id] = 'Away';
                              });
                              final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                              betSlip.addOrUpdateSelection(BetSelection(
                                matchId: match.id,
                                matchTitle: '${match.teamA} vs ${match.teamB}',
                                market: mainMarketKey ?? '',
                                oddKey: 'Away',
                                oddValue: double.tryParse((oddsMap[mainMarketKey]?['Away']?.toString() ?? '0')) ?? 0.0,
                              ));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                                Text(awayOdd ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                        if (moreMarkets.isNotEmpty)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.more_horiz, color: Colors.blue, size: 28),
                              tooltip: 'More Markets',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                    builder: (_) => _MoreMarketsModal(
                                      match: match,
                                      moreMarkets: moreMarkets,
                                      oddsMap: oddsMap,
                                    ),
                                );
                              },
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                  padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                    ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                ),
                                child: Text(
                                    '${moreMarkets.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                  ),
                                    textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  void _showSportsNavigation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Sports Navigation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      color: Colors.grey[100],
                      child: const TabBar(
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.green,
                        tabs: [
                          Tab(text: 'Sports'),
                          Tab(text: 'Countries'),
                          Tab(text: 'Leagues'),
                          Tab(text: 'Teams'),
                        ],
                      ),
                    ),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Sports Tab
                          _buildSportsTab(),
                          
                          // Countries Tab
                          _buildCountriesTab(),
                          
                          // Leagues Tab
                          _buildLeaguesTab(),
                          
                          // Teams Tab
                          _buildTeamsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _popularSports.length,
      itemBuilder: (context, index) {
        final sport = _popularSports[index];
        final selected = _menuSelectedSport == sport;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: selected ? 4 : 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: selected ? Colors.green[100] : Colors.grey[100],
              child: Icon(
                _sportIcons[sport],
                color: selected ? Colors.green[700] : Colors.grey[600],
              ),
            ),
            title: Text(
              sport,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.green[700] : Colors.black,
              ),
            ),
            subtitle: Text('Select to view ${sport.toLowerCase()} options'),
            trailing: selected ? Icon(Icons.check_circle, color: Colors.green[700]) : null,
            onTap: () {
              setState(() {
                _menuSelectedSport = sport;
                _menuSelectedCountry = null;
                _menuSelectedChampion = null;
                _menuChampions = [];
              });
              _fetchMenuCountriesForSport(sport);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected sport: $sport')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCountriesTab() {
    return StreamBuilder<List<Country>>(
      stream: _firestoreService.getCountries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No countries available'));
        }
        
        final countries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            final selected = _menuSelectedCountry?.id == country.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: selected ? 4 : 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: selected ? Colors.blue[100] : Colors.grey[100],
                  child: Icon(
                    Icons.flag,
                    color: selected ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
                title: Text(
                  country.name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.blue[700] : Colors.black,
                  ),
                ),
                subtitle: Text('Country code: ${country.code}'),
                trailing: selected ? Icon(Icons.check_circle, color: Colors.blue[700]) : null,
                onTap: () {
                  setState(() {
                    _menuSelectedCountry = country;
                    _menuSelectedChampion = null;
                  });
                  _fetchMenuChampionsForCountry(country, _menuSelectedSport);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected country: ${country.name}')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaguesTab() {
    if (_menuSelectedCountry == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a country first to view leagues',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return StreamBuilder<List<Champion>>(
      stream: _firestoreService.getChampionsByCountry(_menuSelectedCountry!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No leagues available for this country'));
        }
        
        final champions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: champions.length,
          itemBuilder: (context, index) {
            final champion = champions[index];
            final selected = _menuSelectedChampion?.id == champion.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: selected ? 4 : 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: selected ? Colors.orange[100] : Colors.grey[100],
                  child: Icon(
                    Icons.emoji_events,
                    color: selected ? Colors.orange[700] : Colors.grey[600],
                  ),
                ),
                title: Text(
                  champion.name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.orange[700] : Colors.black,
                  ),
                ),
                subtitle: Text('${champion.sport} League'),
                trailing: selected ? Icon(Icons.check_circle, color: Colors.orange[700]) : null,
                onTap: () {
                  setState(() {
                    _menuSelectedChampion = champion;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected league: ${champion.name}')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_menuSelectedChampion == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a league first to view teams',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return StreamBuilder<List<Team>>(
      stream: _firestoreService.getTeamsByChampion(_menuSelectedChampion!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No teams available for this league'));
        }
        
        final teams = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            
            return Card(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected team: ${team.name}')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      team.logoUrl != null
                          ? CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(team.logoUrl!),
                              onBackgroundImageError: (_, __) {},
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green[100],
                              child: Icon(
                                _getSportIcon(team.sport),
                                color: Colors.green[700],
                                size: 24,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        team.sport,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  void _autoUpdateMatchStatus(Match match) async {
    final now = DateTime.now();
    if (match.status == 'open' && now.isAfter(match.dateTimeStart)) {
      await FirebaseFirestore.instance.collection('matches').doc(match.id).update({'status': 'live'});
    } else if (match.status == 'live' && now.isAfter(match.dateTimeStart.add(const Duration(minutes: 90)))) {
      await FirebaseFirestore.instance.collection('matches').doc(match.id).update({'status': 'expired'});
    }
  }
}

// Minimal deposit dialog
class _DepositDialog extends StatefulWidget {
  final Future<void> Function(double amount) onDeposit;
  const _DepositDialog({Key? key, required this.onDeposit}) : super(key: key);

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deposit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter amount to deposit:'),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  if (amount <= 0) return;
                  setState(() => _isLoading = true);
                  await widget.onDeposit(amount);
                  setState(() => _isLoading = false);
                },
          child: _isLoading ? const CircularProgressIndicator() : const Text('Deposit'),
        ),
      ],
    );
  }
}

// Replace _MoreMarketsModal with a stateful version that shows expandable markets and selectable options
class _MoreMarketsModal extends StatefulWidget {
  final Match match;
  final List<String> moreMarkets;
  final Map<String, dynamic> oddsMap;

  const _MoreMarketsModal({
    Key? key,
    required this.match,
    required this.moreMarkets,
    required this.oddsMap,
  }) : super(key: key);

  @override
  State<_MoreMarketsModal> createState() => _MoreMarketsModalState();
}

class _MoreMarketsModalState extends State<_MoreMarketsModal> {
  // Track selected option per market
  Map<String, String> selectedOptions = {};

  // Define display order and labels for known markets
  final Map<String, List<String>> marketOptionOrder = {
    '1X2': ['1', 'X', '2'],
    'match_winner': ['Home', 'Draw', 'Away'],
    'Double Chance': ['1X', 'X2', '12'],
    'Both Teams To Score': ['Yes', 'No'],
    'Over/Under': [
      'Over 1.5', 'Under 1.5',
      'Over 2.5', 'Under 2.5',
      'Over 3.5', 'Under 3.5',
    ],
    // Add more known markets and their order here if needed
  };

  // Map for pretty market titles
  final Map<String, String> prettyMarketTitles = {
    '1X2': '1X2 | Full Time',
    'match_winner': '1X2 | Full Time',
    'Double Chance': 'Double Chance | Full Time',
    'Both Teams To Score': 'Both Teams To Score | Full Time',
    'Over/Under': 'Over/Under | Full Time',
  };

  @override
  Widget build(BuildContext context) {
    // Show all markets, with 1X2 always first
    final allMarkets = widget.oddsMap.keys.toList();
    if (allMarkets.contains('1X2')) {
      allMarkets.remove('1X2');
      allMarkets.insert(0, '1X2');
    } else if (allMarkets.contains('match_winner')) {
      allMarkets.remove('match_winner');
      allMarkets.insert(0, 'match_winner');
    }

    final Map<String, String> oneXtwoLabelMap = {
      '1': 'Home',
      'X': 'Draw',
      '2': 'Away',
    };
    final List<String> doubleChanceOrder = ['1X', 'X2', '12'];

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: allMarkets.map((market) {
        final marketOdds = widget.oddsMap[market];
        if (marketOdds is! Map) return const SizedBox(); // skip if not a map
        // 1X2 special case
        if (market == '1X2' || market == 'match_winner') {
          return ExpansionTile(
            initiallyExpanded: true,
            title: const Text('1X2 | Full Time', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['1', 'X', '2'].map((label) {
                  final key = oneXtwoLabelMap[label]!;
                  final value = marketOdds[key]?.toString();
                  final displayValue = (value != null && value.isNotEmpty) ? value : '-';
                  final isSelected = selectedOptions[market] == label;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    onSelected: (_) {
                      setState(() {
                        selectedOptions[market] = label;
                      });
                      // Add selection to betslip
                      final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                      betSlip.addOrUpdateSelection(BetSelection(
                        matchId: widget.match.id,
                        matchTitle: '${widget.match.teamA} vs ${widget.match.teamB}',
                        market: market,
                        oddKey: label,
                        oddValue: double.tryParse(value ?? '0') ?? 0.0,
                      ));
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }
        // Double Chance special case
        if (market == 'Double Chance') {
          return ExpansionTile(
            title: const Text('Double Chance | Full Time', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doubleChanceOrder.map((label) {
                  final value = marketOdds[label]?.toString();
                  final displayValue = (value != null && value.isNotEmpty) ? value : '-';
                  final isSelected = selectedOptions[market] == label;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    onSelected: (_) {
                      setState(() {
                        selectedOptions[market] = label;
                      });
                      // Add selection to betslip
                      final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                      betSlip.addOrUpdateSelection(BetSelection(
                        matchId: widget.match.id,
                        matchTitle: '${widget.match.teamA} vs ${widget.match.teamB}',
                        market: market,
                        oddKey: label,
                        oddValue: double.tryParse(value ?? '0') ?? 0.0,
                      ));
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }
        // Default for other markets
        final prettyTitle = prettyMarketTitles[market] ?? market;
        final optionOrder = marketOptionOrder[market] ?? marketOdds.keys.toList();
        return ExpansionTile(
          title: Text(prettyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: optionOrder.map<Widget>((key) {
                final value = marketOdds[key]?.toString();
                final displayValue = (value != null && value.isNotEmpty) ? value : '-';
                final isSelected = selectedOptions[market] == key;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: Colors.green,
                  onSelected: (_) {
                    setState(() {
                      selectedOptions[market] = key;
                    });
                    // Add selection to betslip
                    final betSlip = Provider.of<BetSlipProvider>(context, listen: false);
                    betSlip.addOrUpdateSelection(BetSelection(
                      matchId: widget.match.id,
                      matchTitle: '${widget.match.teamA} vs ${widget.match.teamB}',
                      market: market,
                      oddKey: key,
                      oddValue: double.tryParse(value ?? '0') ?? 0.0,
                    ));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
} 

class _MatchDetailsModal extends StatelessWidget {
  final Match match;
  const _MatchDetailsModal({required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${match.teamA} vs ${match.teamB}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(width: 12),
              if (match.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if ((match.marketingLabel ?? '').toLowerCase() == 'boosted')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('BOOSTED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Category: ${match.category}', style: const TextStyle(fontSize: 16)),
          Text('Sport: ${match.sport}', style: const TextStyle(fontSize: 16)),
          Text('Start: ${DateFormat('h:mm a EEE dd/MM').format(match.dateTimeStart)}', style: const TextStyle(fontSize: 16)),
          Text('Status: ${match.status}', style: const TextStyle(fontSize: 16)),
          if (match.marketingLabel != null)
            Text('Label: ${match.marketingLabel}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text('Responsibilities:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          // Add more responsibility info here if available in your model
          Text('Match ID: ${match.id}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  } 
}

// Recommended MFA Enroll Widget for SMS

class MfaEnrollWidget extends StatefulWidget {
  const MfaEnrollWidget({super.key});

  @override
  _MfaEnrollWidgetState createState() => _MfaEnrollWidgetState();
}

class _MfaEnrollWidgetState extends State<MfaEnrollWidget> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  String? _status;

  Future<void> enrollMfa() async {
    setState(() { _isLoading = true; _status = null; });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final session = await user.multiFactor.getSession();

      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        multiFactorSession: session,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {},
        verificationFailed: (e) {
          setState(() { _status = 'Verification failed: [31m${e.message}[0m'; _isLoading = false; });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _status = 'Code sent! Enter the code below.';
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      setState(() { _status = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> verifyAndEnroll() async {
    setState(() { _isLoading = true; _status = null; });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      final assertion = firebase_auth.PhoneMultiFactorGenerator.getAssertion(credential);
      await user.multiFactor.enroll(assertion, displayName: 'My Phone');
      setState(() { _status = 'MFA enrolled successfully!'; _isLoading = false; });
    } catch (e) {
      setState(() { _status = 'Error: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('Enroll SMS Multi-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone number (+2507xxxxxxx)'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : enrollMfa,
          child: const Text('Send Verification Code'),
        ),
        if (_verificationId != null) ...[
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Verification code'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : verifyAndEnroll,
            child: const Text('Verify & Enroll'),
          ),
        ],
        if (_status != null) Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_status!, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}

// Add this widget at the top of the file or in a suitable place
class LiveMatchTimer extends StatefulWidget {
  final DateTime startTime;
  final bool isLive;
  const LiveMatchTimer({required this.startTime, required this.isLive, super.key});

  @override
  State<LiveMatchTimer> createState() => _LiveMatchTimerState();
}

class _LiveMatchTimerState extends State<LiveMatchTimer> {
  late int minutesElapsed;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateMinutes();
    if (widget.isLive) {
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
        setState(() {
          _updateMinutes();
        });
      });
    }
  }

  void _updateMinutes() {
    final now = DateTime.now();
    minutesElapsed = now.difference(widget.startTime).inMinutes;
    if (minutesElapsed < 0) minutesElapsed = 0;
    if (minutesElapsed > 90) minutesElapsed = 90;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) return const SizedBox.shrink();
    return Text(
      'Live: $minutesElapsed\'',
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}