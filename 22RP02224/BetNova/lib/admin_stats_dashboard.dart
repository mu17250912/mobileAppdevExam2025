import 'package:flutter/material.dart';
import 'admin_country_team_management.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsDashboard extends StatefulWidget {
  const AdminStatsDashboard({super.key});

  @override
  State<AdminStatsDashboard> createState() => _AdminStatsDashboardState();
}

class _AdminStatsDashboardState extends State<AdminStatsDashboard> {
  bool _isSeeding = false;
  bool _seeded = false;
  bool _deleteComplete = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _seedData() async {
    setState(() { _isSeeding = true; });
    try {
      // Check if data already exists
      final countries = await FirestoreService().db.collection('countries').get();
      final champions = await FirestoreService().db.collection('champions').get();
      final teams = await FirestoreService().db.collection('teams').get();
      if (countries.docs.isNotEmpty || champions.docs.isNotEmpty || teams.docs.isNotEmpty) {
        setState(() { _isSeeding = false; _seeded = true; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data already seeded!'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      await FirestoreService().seedExampleData();
      setState(() { _isSeeding = false; _seeded = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Example data seeded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeAndReseed() async {
    setState(() { _isSeeding = true; });
    try {
      // Remove all data
      for (final col in ['countries', 'champions', 'teams']) {
        final docs = await FirestoreService().db.collection(col).get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      }
      // Reseed
      await FirestoreService().seedExampleData();
      setState(() { _isSeeding = false; _seeded = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data removed and reseeded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove and reseed failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSeededData() async {
    setState(() { _isSeeding = true; _deleteComplete = false; });
    try {
      for (final col in ['countries', 'champions', 'teams']) {
        QuerySnapshot snapshot;
        do {
          snapshot = await FirestoreService().db.collection(col).limit(500).get();
          if (snapshot.docs.isEmpty) break;
          WriteBatch batch = FirestoreService().db.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } while (snapshot.docs.isNotEmpty);
      }
      setState(() { _isSeeding = false; _deleteComplete = true; _seeded = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data deleted!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _insertSeededData() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().seedExampleData();
      setState(() { _isSeeding = false; _seeded = true; _deleteComplete = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data seeded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seeding failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fixChampionsCountryName() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().fixChampionsCountryName();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Champions countryName field fixed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fix failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addMissingTeams() async {
    setState(() { _isSeeding = true; });
    try {
      // This is a simplified version - you might want to load from JSON files
      final firestoreService = FirestoreService();
      
      // Get all champions
      final champions = await firestoreService.getChampions().first;
      print('Debug: Found ${champions.length} champions to check for teams');
      
      for (final champion in champions) {
        final teams = await firestoreService.getTeamsByChampionFuture(champion.id);
        if (teams.isEmpty) {
          print('Debug: No teams found for champion: ${champion.name}');
          // You could add some default teams here or load from JSON
          // For now, just add a placeholder
          await firestoreService.db.collection('teams').add({
            'name': 'Team A',
            'championId': champion.id,
            'sport': champion.sport,
          });
          await firestoreService.db.collection('teams').add({
            'name': 'Team B',
            'championId': champion.id,
            'sport': champion.sport,
          });
        }
      }
      
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing teams added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add teams failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkDataStatus() async {
    try {
      final countries = await FirestoreService().db.collection('countries').get();
      final champions = await FirestoreService().db.collection('champions').get();
      final teams = await FirestoreService().db.collection('teams').get();
      
      String message = 'Data Status:\n';
      message += 'Countries: ${countries.docs.length}\n';
      message += 'Champions: ${champions.docs.length}\n';
      message += 'Teams: ${teams.docs.length}';
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Current Data Status'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncTeamsFromAssets() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().syncTeamsFromAssets();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teams synced from assets!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reconcileTeamsWithChampions() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().reconcileTeamsWithChampionsFromAssets();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teams reconciled with champions!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reconciliation failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addSearchableTextToDocuments() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().addSearchableTextToExistingDocuments();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SearchableText added to all documents!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add searchableText failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addTestDataForSearch() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().addTestDataForSearch();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test data added for search!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add test data failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addQuickTestData() async {
    setState(() { _isSeeding = true; });
    try {
      await FirestoreService().addQuickTestData();
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick test data added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _isSeeding = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add quick test data failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() { _isSearching = true; });
    
    try {
      final searchText = query.toLowerCase();
      final searchTextEnd = '$searchText\uf8ff';
      
      final results = await Future.wait([
        // Search in matches
        FirebaseFirestore.instance
            .collection('matches')
            .where('searchableText', isGreaterThanOrEqualTo: searchText)
            .where('searchableText', isLessThan: searchTextEnd)
            .limit(10)
            .get(),
        // Search in countries
        FirebaseFirestore.instance
            .collection('countries')
            .where('searchableText', isGreaterThanOrEqualTo: searchText)
            .where('searchableText', isLessThan: searchTextEnd)
            .limit(5)
            .get(),
        // Search in champions
        FirebaseFirestore.instance
            .collection('champions')
            .where('searchableText', isGreaterThanOrEqualTo: searchText)
            .where('searchableText', isLessThan: searchTextEnd)
            .limit(5)
            .get(),
        // Search in teams
        FirebaseFirestore.instance
            .collection('teams')
            .where('searchableText', isGreaterThanOrEqualTo: searchText)
            .where('searchableText', isLessThan: searchTextEnd)
            .limit(5)
            .get(),
      ]);

      final allResults = <Map<String, dynamic>>[];
      
      // Add matches
      for (final doc in results[0].docs) {
        final data = doc.data();
        allResults.add({
          'type': 'match',
          'id': doc.id,
          'title': '${data['teamA']} vs ${data['teamB']}',
          'subtitle': '${data['category']} / ${data['sport']}',
          'data': data,
        });
      }
      
      // Add countries
      for (final doc in results[1].docs) {
        final data = doc.data();
        allResults.add({
          'type': 'country',
          'id': doc.id,
          'title': data['name'] ?? '',
          'subtitle': 'Country',
          'data': data,
        });
      }
      
      // Add champions
      for (final doc in results[2].docs) {
        final data = doc.data();
        allResults.add({
          'type': 'champion',
          'id': doc.id,
          'title': data['name'] ?? '',
          'subtitle': '${data['sport']} League',
          'data': data,
        });
      }
      
      // Add teams
      for (final doc in results[3].docs) {
        final data = doc.data();
        allResults.add({
          'type': 'team',
          'id': doc.id,
          'title': data['name'] ?? '',
          'subtitle': 'Team',
          'data': data,
        });
      }

      setState(() {
        _searchResults = allResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() { _isSearching = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BetNova Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AdminSearchDelegate(_performSearch),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar at the top of home screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                                  BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '🔍 Search matches, countries, teams, leagues...',
                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                  suffixIcon: _isSearching 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                      )
                    : _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() { _searchQuery = value; });
                  _performSearch(value);
                },
              ),
            ),
          ),
          // Search results
          if (_searchResults.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getIconForType(result['type']),
                      title: Text(result['title']),
                      subtitle: Text(result['subtitle']),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _handleResultTap(result),
                      ),
                      onTap: () => _handleResultTap(result),
                    ),
                  );
                },
              ),
            ),
          ] else if (_searchQuery.isNotEmpty && !_isSearching) ...[
            const Expanded(
              child: Center(
                child: Text('No results found'),
              ),
            ),
          ] else ...[
            // Main dashboard content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.shade100, Colors.blue.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'BetNova Admin Dashboard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Welcome to your sports betting management system',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 1. Make Total User Balance card clickable
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('User Balances & Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const Divider(height: 1),
                                Flexible(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 600),
                                      // Show only the table, no Card
                                      child: const AdminUserBalancesTable(showCard: false),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const AdminTotalUserBalanceCard(),
                    ),
                    // --- Firestore Analytics Cards ---
                    FutureBuilder<Map<String, dynamic>>(
                      future: FirestoreService().getStatistics(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.hasError) {
                          return const Text('Failed to load statistics');
                        }
                        final stats = snapshot.data!;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Total Users', stats['totalUsers'].toString(), Icons.person, Colors.deepPurple),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Total Matches', stats['totalMatches'].toString(), Icons.sports_soccer, Colors.green),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Total Bets', stats['totalBets'].toString(), Icons.stacked_line_chart, Colors.blue),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Pending Bets', stats['pendingBets'].toString(), Icons.hourglass_empty, Colors.orange),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Won Bets', stats['wonBets'].toString(), Icons.emoji_events, Colors.teal),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: _buildStatCard('Lost Bets', stats['lostBets'].toString(), Icons.cancel, Colors.red),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // --- End Firestore Analytics Cards ---
                    // --- User Balances & Transactions ---
                    // Remove the big AdminUserBalancesTable from the dashboard main view.
                    // Instead, add this ListTile-style card:
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('User Balances & Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const Divider(height: 1),
                                Flexible(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 600),
                                      child: const AdminUserBalancesTable(showCard: false),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Card(
                        margin: EdgeInsets.all(16),
                        child: ListTile(
                          leading: Icon(Icons.account_balance_wallet, color: Colors.orange),
                          title: Text('User Balances & Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                    // --- End User Balances & Transactions ---
                    // --- Recent User Activities ---
                    // 2. Make Recent User Activities card clickable
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(child: buildRecentUserActivities()),
                          ),
                        );
                      },
                      child: const Card(
                        margin: EdgeInsets.all(16),
                        child: ListTile(
                          leading: Icon(Icons.history, color: Colors.deepPurple),
                          title: Text('Recent User Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                    // --- End Recent User Activities ---
                    const Text(
                      'Admin Controls',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flag),
                      label: const Text('Manage Countries & Teams'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminCountryTeamManagement(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Seeded Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _deleteSeededData,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Insert Seed Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding || !_deleteComplete ? null : _insertSeededData,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.build),
                      label: const Text('Fix Champions CountryName'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _fixChampionsCountryName,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sports_soccer),
                      label: const Text('Add Missing Teams'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _addMissingTeams,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.info),
                      label: const Text('Check Data Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _checkDataStatus,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Teams from Assets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _syncTeamsFromAssets,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Reconcile Champions & Teams'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _reconcileTeamsWithChampions,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Add SearchableText to Documents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _addSearchableTextToDocuments,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sports_soccer),
                      label: const Text('Add Test Data for Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSeeding ? null : _addTestDataForSearch,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Add Quick Test Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isSeeding ? null : _addQuickTestData,
                    ),
                    const SizedBox(height: 16), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'match':
        return const Icon(Icons.sports_soccer, color: Colors.green);
      case 'country':
        return const Icon(Icons.flag, color: Colors.blue);
      case 'champion':
        return const Icon(Icons.emoji_events, color: Colors.orange);
      case 'team':
        return const Icon(Icons.sports, color: Colors.purple);
      default:
        return const Icon(Icons.search, color: Colors.grey);
    }
  }

  void _handleResultTap(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'match':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit match: 27${result['title']}27')),
        );
        break;
      case 'country':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit country: 27${result['title']}27')),
        );
        break;
      case 'champion':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit league: 27${result['title']}27')),
        );
        break;
      case 'team':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit team: 27${result['title']}27')),
        );
        break;
    }
  }
}

class AdminEventLogWidget extends StatelessWidget {
  const AdminEventLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Recent User Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_events')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No events yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['event'] ?? 'Unknown Event'),
                      subtitle: Text('User: A${data['userEmail'] ?? data['userId'] ?? 'Unknown'}\nParams: ${data['params']?.toString() ?? ''}'),
                      trailing: Text(data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Move AdminSearchDelegate outside of _AdminStatsDashboardState
class AdminSearchDelegate extends SearchDelegate {
  final Function(String) onSearch;

  AdminSearchDelegate(this.onSearch);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search...'));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: _getIconForType(result['type']),
              title: Text(result['title']),
              subtitle: Text(result['subtitle']),
              onTap: () {
                close(context, result);
              },
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

  Future<List<Map<String, dynamic>>> _performSearch(String query) async {
    if (query.trim().isEmpty) return [];
    final searchText = query.toLowerCase();
    final searchTextEnd = '$searchText\uf8ff';
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('matches')
          .where('searchableText', isGreaterThanOrEqualTo: searchText)
          .where('searchableText', isLessThan: searchTextEnd)
          .limit(10)
          .get(),
      FirebaseFirestore.instance
          .collection('countries')
          .where('searchableText', isGreaterThanOrEqualTo: searchText)
          .where('searchableText', isLessThan: searchTextEnd)
          .limit(5)
          .get(),
      FirebaseFirestore.instance
          .collection('champions')
          .where('searchableText', isGreaterThanOrEqualTo: searchText)
          .where('searchableText', isLessThan: searchTextEnd)
          .limit(5)
          .get(),
      FirebaseFirestore.instance
          .collection('teams')
          .where('searchableText', isGreaterThanOrEqualTo: searchText)
          .where('searchableText', isLessThan: searchTextEnd)
          .limit(5)
          .get(),
    ]);
    final allResults = <Map<String, dynamic>>[];
    for (final doc in results[0].docs) {
      final data = doc.data();
      allResults.add({
        'type': 'match',
        'id': doc.id,
        'title': '${data['teamA']} vs ${data['teamB']}',
        'subtitle': '${data['category']} / ${data['sport']}',
        'data': data,
      });
    }
    for (final doc in results[1].docs) {
      final data = doc.data();
      allResults.add({
        'type': 'country',
        'id': doc.id,
        'title': data['name'] ?? '',
        'subtitle': 'Country',
        'data': data,
      });
    }
    for (final doc in results[2].docs) {
      final data = doc.data();
      allResults.add({
        'type': 'champion',
        'id': doc.id,
        'title': data['name'] ?? '',
        'subtitle': '${data['sport']} League',
        'data': data,
      });
    }
    for (final doc in results[3].docs) {
      final data = doc.data();
      allResults.add({
        'type': 'team',
        'id': doc.id,
        'title': data['name'] ?? '',
        'subtitle': 'Team',
        'data': data,
      });
    }
    return allResults;
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'match':
        return const Icon(Icons.sports_soccer, color: Colors.green);
      case 'country':
        return const Icon(Icons.flag, color: Colors.blue);
      case 'champion':
        return const Icon(Icons.emoji_events, color: Colors.orange);
      case 'team':
        return const Icon(Icons.sports, color: Colors.purple);
      default:
        return const Icon(Icons.search, color: Colors.grey);
    }
  }
} 

// Helper widget for stat cards
Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    ),
  );
} 

// --- UsersBalanceSection Widget ---
class _UsersBalanceSection extends StatefulWidget {
  @override
  State<_UsersBalanceSection> createState() => _UsersBalanceSectionState();
}

class _UsersBalanceSectionState extends State<_UsersBalanceSection> {
  String _search = '';
  bool _sortAsc = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Users & Balances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by email or name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              ),
            ),
            IconButton(
              icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.deepPurple),
              tooltip: 'Sort by balance',
              onPressed: () => setState(() => _sortAsc = !_sortAsc),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return const Text('Failed to load users');
            }
            var docs = snapshot.data!.docs;
            List<Map<String, dynamic>> users = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'email': data['email'] ?? '',
                'name': data['name'] ?? '',
                'balance': (data['balance'] as num?)?.toDouble() ?? 0.0,
              };
            }).toList();
            // Search
            if (_search.isNotEmpty) {
              users = users.where((u) => u['email'].toString().toLowerCase().contains(_search) || u['name'].toString().toLowerCase().contains(_search)).toList();
            }
            // Sort
            users.sort((a, b) => _sortAsc ? a['balance'].compareTo(b['balance']) : b['balance'].compareTo(a['balance']));
            return users.isEmpty
                ? const Text('No users found')
                : Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Balance (RWF)')),
                      ],
                      rows: users.map((u) => DataRow(cells: [
                        DataCell(Text(u['name'] ?? '')),
                        DataCell(Text(u['email'] ?? '')),
                        DataCell(Text(u['balance'].toStringAsFixed(2))),
                      ])).toList(),
                    ),
                  );
          },
        ),
      ],
    );
  }
}
// --- End UsersBalanceSection Widget --- 

class AdminUserBalancesTable extends StatelessWidget {
  const AdminUserBalancesTable({super.key, this.showCard = true});

  final bool showCard;

  Future<Map<String, double>> _getTotals(String userId) async {
    final events = await FirebaseFirestore.instance
        .collection('admin_events')
        .where('userId', isEqualTo: userId)
        .get();
    double deposit = 0, withdraw = 0;
    for (var doc in events.docs) {
      final data = doc.data();
      final event = data['event'];
      final amount = (data['params']?['amount'] as num?)?.toDouble() ?? 0.0;
      if (event == 'deposit') deposit += amount;
      if (event == 'withdraw') withdraw += amount;
    }
    return {'deposit': deposit, 'withdraw': withdraw};
  }

  @override
  Widget build(BuildContext context) {
    return showCard ? Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Balances & Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;
                if (users.isEmpty) return const Text('No users found.');
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Email/Phone')),
                      DataColumn(label: Text('Balance')),
                      DataColumn(label: Text('Total Deposited')),
                      DataColumn(label: Text('Total Withdrawn')),
                    ],
                    rows: users.map((userDoc) {
                      final user = userDoc.data() as Map<String, dynamic>;
                      final userId = userDoc.id;
                      final emailOrPhone = user['phone'] ?? user['email'] ?? '';
                      final balance = (user['balance'] as num?)?.toDouble() ?? 0.0;
                      return DataRow(cells: [
                        DataCell(Text(emailOrPhone)),
                        DataCell(Text(balance.toStringAsFixed(2))),
                        DataCell(FutureBuilder<Map<String, double>>(
                          future: _getTotals(userId),
                          builder: (context, snap) {
                            if (!snap.hasData) return const Text('...');
                            return Text(snap.data!['deposit']!.toStringAsFixed(2));
                          },
                        )),
                        DataCell(FutureBuilder<Map<String, double>>(
                          future: _getTotals(userId),
                          builder: (context, snap) {
                            if (!snap.hasData) return const Text('...');
                            return Text(snap.data!['withdraw']!.toStringAsFixed(2));
                          },
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ) : Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Balances & Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs;
              if (users.isEmpty) return const Text('No users found.');
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Email/Phone')),
                    DataColumn(label: Text('Balance')),
                    DataColumn(label: Text('Total Deposited')),
                    DataColumn(label: Text('Total Withdrawn')),
                  ],
                  rows: users.map((userDoc) {
                    final user = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final emailOrPhone = user['phone'] ?? user['email'] ?? '';
                    final balance = (user['balance'] as num?)?.toDouble() ?? 0.0;
                    return DataRow(cells: [
                      DataCell(Text(emailOrPhone)),
                      DataCell(Text(balance.toStringAsFixed(2))),
                      DataCell(FutureBuilder<Map<String, double>>(
                        future: _getTotals(userId),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Text('...');
                          return Text(snap.data!['deposit']!.toStringAsFixed(2));
                        },
                      )),
                      DataCell(FutureBuilder<Map<String, double>>(
                        future: _getTotals(userId),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Text('...');
                          return Text(snap.data!['withdraw']!.toStringAsFixed(2));
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 

Widget buildRecentUserActivities() {
  return Card(
    margin: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Recent User Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_events')
              .orderBy('timestamp', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recent activities.', style: TextStyle(color: Colors.grey)),
            );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final event = data['event'] ?? 'activity';
                final user = data['userEmail'] ?? data['userId'] ?? 'Unknown';
                final params = data['params'] ?? {};
                final amount = params['amount'];
                final ts = data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : null;

                // Choose icon and color
                IconData icon;
                Color color;
                String actionText;
                switch (event) {
                  case 'login':
                    icon = Icons.login;
                    color = Colors.deepPurple;
                    actionText = 'Login';
                    break;
                  case 'logout':
                    icon = Icons.logout;
                    color = Colors.grey;
                    actionText = 'Logout';
                    break;
                  case 'deposit':
                    icon = Icons.arrow_downward;
                    color = Colors.green;
                    actionText = 'Deposit';
                    break;
                  case 'withdraw':
                    icon = Icons.arrow_upward;
                    color = Colors.red;
                    actionText = 'Withdraw';
                    break;
                  case 'bet_placed':
                    icon = Icons.sports_soccer;
                    color = Colors.blue;
                    actionText = 'Bet Placed';
                    break;
                  default:
                    icon = Icons.info;
                    color = Colors.orange;
                    actionText = event.toString();
                }

                return ListTile(
                  leading: CircleAvatar(
                                                backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text('$actionText by $user', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  subtitle: amount != null
                      ? Text('Amount: $amount', style: const TextStyle(color: Colors.black87))
                      : null,
                  trailing: ts != null
                      ? Text('${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey))
                      : null,
                );
              },
            );
          },
        ),
      ],
    ),
  );
} 

class AdminTotalUserBalanceCard extends StatelessWidget {
  const AdminTotalUserBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _RealtimeStatCard(
            label: 'Total User Balance',
            icon: Icons.account_balance_wallet,
            color: Colors.orange,
            onTap: () {},
            value: '... RWF',
            isMoney: true,
          );
        }
        final docs = snapshot.data!.docs;
        double total = 0;
        for (var doc in docs) {
          final balance = (doc['balance'] as num?)?.toDouble() ?? 0.0;
          total += balance;
        }
        return _RealtimeStatCard(
          label: 'Total User Balance',
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          onTap: () {},
          value: '${total.toStringAsFixed(2)} RWF',
          isMoney: true,
        );
      },
    );
  }
}

// Update _RealtimeStatCard to accept a value parameter for custom display
class _RealtimeStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? value;
  final bool isMoney;

  const _RealtimeStatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.value,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 