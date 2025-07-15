import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  // Helper function to create searchable text for prefix search
  String createSearchableText(String text) {
    return text.toLowerCase().trim();
  }

  // Country Management
  Future<void> addCountry(Country country) async {
    await db.collection('countries').add(country.toMap());
  }

  Future<void> updateCountry(String id, Map<String, dynamic> data) async {
    await db.collection('countries').doc(id).update(data);
  }

  Future<void> deleteCountry(String id) async {
    await db.collection('countries').doc(id).delete();
  }

  Stream<List<Country>> getCountries() {
    return db.collection('countries')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Country.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Team Management
  Future<void> addTeam(Team team) async {
    await db.collection('teams').add(team.toMap());
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) async {
    await db.collection('teams').doc(id).update(data);
  }

  Future<void> deleteTeam(String id) async {
    await db.collection('teams').doc(id).delete();
  }

  Stream<List<Team>> getTeams() {
    return db.collection('teams')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Team>> getTeamsByCountry(String countryId) {
    return db.collection('teams')
        .where('countryId', isEqualTo: countryId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Team>> getTeamsBySport(String sport) {
    return db.collection('teams')
        .where('sport', isEqualTo: sport)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Team>> getTeamsByCountryAndSport(String countryId, String sport) {
    return db.collection('teams')
        .where('countryId', isEqualTo: countryId)
        .where('sport', isEqualTo: sport)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Team>> getTeamsByChampion(String championId) {
    return db.collection('teams')
        .where('championId', isEqualTo: championId)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map((doc) => Team.fromMap(doc.id, doc.data()))
              .toList();
          // Sort in memory to avoid index requirement
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        });
  }

  // Method to check if teams exist for a champion
  Future<List<Team>> getTeamsByChampionFuture(String championId) async {
    final snapshot = await db.collection('teams')
        .where('championId', isEqualTo: championId)
        .get();
    
    final teams = snapshot.docs
        .map((doc) => Team.fromMap(doc.id, doc.data()))
        .toList();
    // Sort in memory to avoid index requirement
    teams.sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  // Method to add missing teams for a champion
  Future<void> addMissingTeamsForChampion(String championId, String championName, List<String> teamNames) async {
    
    // Get existing teams for this champion
    final existingTeams = await getTeamsByChampionFuture(championId);
    final existingTeamNames = existingTeams.map((t) => t.name).toSet();
    
    // Add missing teams
    for (final teamName in teamNames) {
      if (!existingTeamNames.contains(teamName)) {
        await db.collection('teams').add({
          'name': teamName,
          'championId': championId,
          'sport': 'Football', // Default, you might want to get this from the champion
        });
      }
    }
  }

  // Match Management
  Future<void> addMatch(Match match) async {
    await db.collection('matches').add(match.toMap());
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) async {
    await db.collection('matches').doc(id).update(data);
  }

  Future<void> deleteMatch(String id) async {
    await db.collection('matches').doc(id).delete();
  }

  Stream<List<Match>> getMatches() {
    return db.collection('matches')
        .orderBy('dateTimeStart', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Match>> getVisibleMatches() {
    return db.collection('matches')
        .where('visible', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .orderBy('dateTimeStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Match>> getLiveMatches() {
    return db.collection('matches')
        .where('status', isEqualTo: 'live')
        .where('visible', isEqualTo: true)
        .orderBy('dateTimeStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Match>> getUpcomingMatches() {
    final now = DateTime.now();
    return db.collection('matches')
        .where('dateTimeStart', isGreaterThan: now)
        .where('visible', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .orderBy('dateTimeStart')
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Match>> getMatchesByCategory(String category) {
    return db.collection('matches')
        .where('category', isEqualTo: category)
        .where('visible', isEqualTo: true)
        .orderBy('dateTimeStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Match>> getTrendingMatches() {
    return db.collection('matches')
        .where('marketingLabel', isEqualTo: 'Trending')
        .where('visible', isEqualTo: true)
        .orderBy('dateTimeStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Bet Management
  Future<void> addBet(Bet bet) async {
    await db.collection('bets').add(bet.toMap());
  }

  Future<void> updateBet(String id, Map<String, dynamic> data) async {
    await db.collection('bets').doc(id).update(data);
  }

  Future<void> deleteBet(String id) async {
    await db.collection('bets').doc(id).delete();
  }

  Stream<List<Bet>> getBets() {
    return db.collection('bets')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Bet>> getBetsForUser(String userId) {
    return db.collection('bets')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Bet>> getBetsByStatus(String status) {
    return db.collection('bets')
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Bet>> getBetsForMatch(String matchId) {
    return db.collection('bets')
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bet.fromMap(doc.id, doc.data()))
            .toList());
  }

  // User Management
  Future<void> addUser(User user) async {
    await db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await db.collection('users').doc(id).update(data);
  }

  Future<User?> getUser(String id) async {
    final doc = await db.collection('users').doc(id).get();
    if (doc.exists) {
      return User.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> updateUserBalance(String userId, double newBalance) async {
    await db.collection('users').doc(userId).update({'balance': newBalance});
  }

  Stream<List<User>> getUsers() {
    return db.collection('users')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final usersSnapshot = await db.collection('users').get();
    final matchesSnapshot = await db.collection('matches').get();
    final betsSnapshot = await db.collection('bets').get();

    final totalUsers = usersSnapshot.docs.length;
    final totalMatches = matchesSnapshot.docs.length;
    final totalBets = betsSnapshot.docs.length;

    final pendingBets = betsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;

    final wonBets = betsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'won')
        .length;

    final lostBets = betsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'lost')
        .length;

    return {
      'totalUsers': totalUsers,
      'totalMatches': totalMatches,
      'totalBets': totalBets,
      'pendingBets': pendingBets,
      'wonBets': wonBets,
      'lostBets': lostBets,
    };
  }

  // Helper methods
  Future<Country?> getCountry(String id) async {
    final doc = await db.collection('countries').doc(id).get();
    if (doc.exists) {
      return Country.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Team?> getTeam(String id) async {
    final doc = await db.collection('teams').doc(id).get();
    if (doc.exists) {
      return Team.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Match?> getMatch(String id) async {
    final doc = await db.collection('matches').doc(id).get();
    if (doc.exists) {
      return Match.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Bet?> getBet(String id) async {
    final doc = await db.collection('bets').doc(id).get();
    if (doc.exists) {
      return Bet.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Champion/League Management
  Future<void> addChampion(Champion champion) async {
    await db.collection('champions').add(champion.toMap());
  }

  Future<void> updateChampion(String id, Map<String, dynamic> data) async {
    await db.collection('champions').doc(id).update(data);
  }

  Future<void> deleteChampion(String id) async {
    await db.collection('champions').doc(id).delete();
  }

  Stream<List<Champion>> getChampions() {
    return db.collection('champions')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Champion.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Champion>> getChampionsByCountryAndSport(String countryId, String sport) {
    return db.collection('champions')
        .where('countryId', isEqualTo: countryId)
        .where('sport', isEqualTo: sport)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Champion.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Champion>> getChampionsByCountry(String countryId) {
    return db.collection('champions')
        .where('countryId', isEqualTo: countryId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Champion.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // More robust method that tries both countryId and countryName
  Future<List<Champion>> getChampionsByCountryRobust(String countryId, String countryName) async {
    
    try {
      // Try with countryId first (without ordering to avoid index requirement)
      final countryIdQuery = await db.collection('champions')
          .where('countryId', isEqualTo: countryId)
          .get();
      
      if (countryIdQuery.docs.isNotEmpty) {
        final champions = countryIdQuery.docs
            .map((doc) => Champion.fromMap(doc.id, doc.data()))
            .toList();
        // Sort in memory to avoid index requirement
        champions.sort((a, b) => a.name.compareTo(b.name));
        return champions;
      }
      
      // If no results, try with countryName
      final countryNameQuery = await db.collection('champions')
          .where('countryName', isEqualTo: countryName)
          .get();
      
      final champions = countryNameQuery.docs
          .map((doc) => Champion.fromMap(doc.id, doc.data()))
          .toList();
      // Sort in memory to avoid index requirement
      champions.sort((a, b) => a.name.compareTo(b.name));
      return champions;
      
    } catch (e) {
      
      // Fallback: get all champions and filter in memory
      final allChampions = await db.collection('champions').get();
      final filteredChampions = allChampions.docs
          .map((doc) => Champion.fromMap(doc.id, doc.data()))
          .where((champion) => 
              champion.countryId == countryId || 
              champion.countryName == countryName)
          .toList();
      
      // Sort in memory
      filteredChampions.sort((a, b) => a.name.compareTo(b.name));
      return filteredChampions;
    }
  }

  Future<void> seedExampleData() async {
    // Clean up previous data
    for (final col in ['countries', 'champions', 'teams']) {
      final docs = await db.collection(col).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Country ISO codes for flags
    final Map<String, String> countryCodes = {
      'Rwanda': 'RW',
      'Kenya': 'KE',
      'Uganda': 'UG',
      'France': 'FR',
      'Japan': 'JP',
      'Iran': 'IR',
      'Sweden': 'SE',
      'Uruguay': 'UY',
      // ... add more as needed for all countries in your assets
    };

    // Step 1: Create all countries and keep a map of their IDs
    final Map<String, String> countryNameToId = {};
    final List<Map<String, dynamic>> allCountries = [];
    // Gather all unique countries from all assets
    for (final asset in [
      'assets/full_international_football_champions.json',
      'assets/international_basketball_champions.json',
      'assets/international_volleyball_champions.json',
    ]) {
      final jsonString = await rootBundle.loadString(asset);
      final List<dynamic> dataset = jsonDecode(jsonString);
      for (final entry in dataset) {
        String country = (entry['country'] as String).trim();
        country = country[0].toUpperCase() + country.substring(1); // Capitalize first letter
        if (!allCountries.any((c) => c['country'] == country)) {
          allCountries.add({'country': country});
        }
      }
    }
    for (final entry in allCountries) {
      final countryName = (entry['country'] as String).trim();
      final code = countryCodes[countryName] ?? countryName.substring(0, 3).toUpperCase();
      final countryRef = await db.collection('countries').add({
        'name': countryName,
        'code': code,
        'searchableText': createSearchableText(countryName),
      });
      countryNameToId[countryName] = countryRef.id;
    }

    // Step 2: Seed each sport, using the correct countryId and storing countryName in champions
    Future<void> seedSport(String assetPath, String sport, String teamKey) async {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> dataset = jsonDecode(jsonString);
      for (final entry in dataset) {
        String country = (entry['country'] as String).trim();
        country = country[0].toUpperCase() + country.substring(1);
        final countryId = countryNameToId[country];
        final championRef = await db.collection('champions').add({
          'name': entry['league'],
          'countryId': countryId,
          'countryName': country, // Store countryName for robust querying
          'sport': sport,
          'searchableText': createSearchableText(entry['league']),
        });
        for (final club in entry[teamKey]) {
          await db.collection('teams').add({
            'name': club,
            'countryId': countryId,
            'championId': championRef.id,
            'sport': sport,
            'searchableText': createSearchableText(club),
          });
        }
      }
    }

    await seedSport('assets/full_international_football_champions.json', 'Football', 'clubs');
    await seedSport('assets/international_basketball_champions.json', 'Basketball', 'teams');
    await seedSport('assets/international_volleyball_champions.json', 'Volleyball', 'clubs');
  }

  Future<bool> countryExists({required String name, required String code}) async {
    final query = await db.collection('countries')
      .where('name', isEqualTo: name)
      .get();
    if (query.docs.isNotEmpty) return true;
    final codeQuery = await db.collection('countries')
      .where('code', isEqualTo: code)
      .get();
    return codeQuery.docs.isNotEmpty;
  }

  // Add a new method to query champions by countryName and sport
  Stream<List<Champion>> getChampionsByCountryNameAndSport(String countryName, String sport) {
    return db.collection('champions')
        .where('countryName', isEqualTo: countryName)
        .where('sport', isEqualTo: sport)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Champion.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Future-based version for better stability
  Future<List<Champion>> getChampionsByCountryNameAndSportFuture(String countryName, String sport) async {
    final snapshot = await db.collection('champions')
        .where('countryName', isEqualTo: countryName)
        .where('sport', isEqualTo: sport)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => Champion.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Method to fix existing champions that don't have countryName field
  Future<void> fixChampionsCountryName() async {
    
    // Get all champions
    final championsSnapshot = await db.collection('champions').get();
    
    for (final doc in championsSnapshot.docs) {
      final data = doc.data();
      if (data['countryName'] == null && data['countryId'] != null) {
        // Get the country name from the countryId
        final countryDoc = await db.collection('countries').doc(data['countryId']).get();
        if (countryDoc.exists) {
          final countryName = countryDoc.data()!['name'];
          await doc.reference.update({'countryName': countryName});
        }
      }
    }
  }

  // Sync teams for all champions/leagues from assets
  Future<void> syncTeamsFromAssets() async {
    // Football
    await _syncTeamsForSport(
      assetPath: 'assets/full_international_football_champions.json',
      sport: 'Football',
      teamKey: 'clubs',
    );
    // Basketball
    await _syncTeamsForSport(
      assetPath: 'assets/international_basketball_champions.json',
      sport: 'Basketball',
      teamKey: 'teams',
    );
    // Volleyball
    await _syncTeamsForSport(
      assetPath: 'assets/international_volleyball_champions.json',
      sport: 'Volleyball',
      teamKey: 'clubs',
    );
  }

  Future<void> _syncTeamsForSport({required String assetPath, required String sport, required String teamKey}) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> dataset = jsonDecode(jsonString);

    for (final entry in dataset) {
      String country = (entry['country'] as String).trim();
      String league = entry['league'];
      // Find champion in Firestore
      final championQuery = await db.collection('champions')
        .where('name', isEqualTo: league)
        .where('sport', isEqualTo: sport)
        .get();
      if (championQuery.docs.isEmpty) continue;
      final championId = championQuery.docs.first.id;
      final countryId = championQuery.docs.first['countryId'];
      // Get all existing teams for this champion in one query
      final existingTeamsSnapshot = await db.collection('teams')
        .where('championId', isEqualTo: championId)
        .get();
      final existingTeamNames = existingTeamsSnapshot.docs.map((doc) => doc['name'] as String).toSet();

      // Prepare batch
      WriteBatch batch = db.batch();
      int batchCount = 0;

      final List<dynamic> teams = entry[teamKey];
      for (final teamName in teams) {
        if (!existingTeamNames.contains(teamName)) {
          final newTeamRef = db.collection('teams').doc();
          batch.set(newTeamRef, {
            'name': teamName,
            'countryId': countryId,
            'championId': championId,
            'sport': sport,
            'searchableText': createSearchableText(teamName),
          });
          batchCount++;
          // Commit batch every 400 teams to avoid Firestore limits
          if (batchCount >= 400) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      }
      if (batchCount > 0) {
        await batch.commit();
      }
    }
  }

  // Reconcile all teams with their correct champions from assets
  Future<void> reconcileTeamsWithChampionsFromAssets() async {
    // 1. Delete all teams
    final allTeams = await db.collection('teams').get();
    for (final doc in allTeams.docs) {
      await doc.reference.delete();
    }
    // 2. Sync teams for each sport/asset
    await _syncTeamsForSport(
      assetPath: 'assets/full_international_football_champions.json',
      sport: 'Football',
      teamKey: 'clubs',
    );
    await _syncTeamsForSport(
      assetPath: 'assets/international_basketball_champions.json',
      sport: 'Basketball',
      teamKey: 'teams',
    );
    await _syncTeamsForSport(
      assetPath: 'assets/international_volleyball_champions.json',
      sport: 'Volleyball',
      teamKey: 'clubs',
    );
  }

  // Get matches by country and champion
  Stream<List<Match>> getMatchesByCountryAndChampion(String countryId, String championId) {
    return db.collection('matches')
      .where('countryId', isEqualTo: countryId)
      .where('championId', isEqualTo: championId)
      .orderBy('dateTimeStart')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Match.fromMap(doc.id, doc.data()))
        .toList());
  }
  
  // Add searchableText to existing documents
  Future<void> addSearchableTextToExistingDocuments() async {
    // Add to countries
    final countries = await db.collection('countries').get();
    for (final doc in countries.docs) {
      final data = doc.data();
      if (data['searchableText'] == null && data['name'] != null) {
        await doc.reference.update({
          'searchableText': createSearchableText(data['name']),
        });
      }
    }
    
    // Add to champions
    final champions = await db.collection('champions').get();
    for (final doc in champions.docs) {
      final data = doc.data();
      if (data['searchableText'] == null && data['name'] != null) {
        await doc.reference.update({
          'searchableText': createSearchableText(data['name']),
        });
      }
    }
    
    // Add to teams
    final teams = await db.collection('teams').get();
    for (final doc in teams.docs) {
      final data = doc.data();
      if (data['searchableText'] == null && data['name'] != null) {
        await doc.reference.update({
          'searchableText': createSearchableText(data['name']),
        });
      }
    }
    
    // Add to matches
    final matches = await db.collection('matches').get();
    for (final doc in matches.docs) {
      final data = doc.data();
      if (data['searchableText'] == null && data['teamA'] != null && data['teamB'] != null) {
        final teamA = data['teamA'] as String;
        final teamB = data['teamB'] as String;
        final category = data['category'] as String? ?? '';
        final sport = data['sport'] as String? ?? '';
        await doc.reference.update({
          'searchableText': '${teamA.toLowerCase()} ${teamB.toLowerCase()} ${category.toLowerCase()} ${sport.toLowerCase()}',
        });
      }
    }
  }

    // Add test data for search functionality
  Future<void> addTestDataForSearch() async {
    try {
      print('Starting to add test data...');
      
      // Get or create England country
      print('Checking for England country...');
      final englandQuery = await db.collection('countries')
          .where('name', isEqualTo: 'England')
          .get();
      
      String englandId;
      if (englandQuery.docs.isEmpty) {
        print('Creating England country...');
        final englandRef = await db.collection('countries').add({
          'name': 'England',
          'code': 'EN',
          'searchableText': 'england',
        });
        englandId = englandRef.id;
        print('England country created with ID: $englandId');
      } else {
        englandId = englandQuery.docs.first.id;
        print('England country found with ID: $englandId');
      }

      // Create Premier League champion
      print('Checking for Premier League champion...');
      final premierLeagueQuery = await db.collection('champions')
          .where('name', isEqualTo: 'Premier League')
          .get();
      
      String premierLeagueId;
      if (premierLeagueQuery.docs.isEmpty) {
        print('Creating Premier League champion...');
        final premierLeagueRef = await db.collection('champions').add({
          'name': 'Premier League',
          'countryId': englandId,
          'countryName': 'England',
          'sport': 'Football',
          'searchableText': 'premier league',
        });
        premierLeagueId = premierLeagueRef.id;
        print('Premier League champion created with ID: $premierLeagueId');
      } else {
        premierLeagueId = premierLeagueQuery.docs.first.id;
        print('Premier League champion found with ID: $premierLeagueId');
      }

      // Add popular teams
      print('Adding popular teams...');
      final popularTeams = [
        'Manchester United',
        'Manchester City',
        'Liverpool',
        'Chelsea',
        'Arsenal',
        'Tottenham Hotspur',
        'Barcelona',
        'Real Madrid',
        'Bayern Munich',
        'Paris Saint-Germain',
        'Juventus',
        'AC Milan',
        'Inter Milan',
        'Ajax',
        'Porto',
        'Benfica',
        'Celtic',
        'Rangers',
        'Galatasaray',
        'Fenerbahce',
      ];

      int teamsAdded = 0;
      for (final teamName in popularTeams) {
        print('Checking for team: $teamName');
        final teamQuery = await db.collection('teams')
            .where('name', isEqualTo: teamName)
            .get();
        
        if (teamQuery.docs.isEmpty) {
          print('Adding team: $teamName');
          await db.collection('teams').add({
            'name': teamName,
            'countryId': englandId,
            'championId': premierLeagueId,
            'sport': 'Football',
            'searchableText': teamName.toLowerCase(),
          });
          teamsAdded++;
        } else {
          print('Team already exists: $teamName');
        }
      }
      print('Added $teamsAdded new teams');

      // Add some test matches
      print('Adding test matches...');
      final testMatches = [
        {
          'teamA': 'Manchester United',
          'teamB': 'Liverpool',
          'category': 'Premier League',
          'sport': 'Football',
        },
        {
          'teamA': 'Manchester City',
          'teamB': 'Arsenal',
          'category': 'Premier League',
          'sport': 'Football',
        },
        {
          'teamA': 'Barcelona',
          'teamB': 'Real Madrid',
          'category': 'La Liga',
          'sport': 'Football',
        },
        {
          'teamA': 'Bayern Munich',
          'teamB': 'Borussia Dortmund',
          'category': 'Bundesliga',
          'sport': 'Football',
        },
      ];

      int matchesAdded = 0;
      for (final matchData in testMatches) {
        print('Checking for match: ${matchData['teamA']} vs ${matchData['teamB']}');
        final matchQuery = await db.collection('matches')
            .where('teamA', isEqualTo: matchData['teamA'])
            .where('teamB', isEqualTo: matchData['teamB'])
            .get();
        
        if (matchQuery.docs.isEmpty) {
          print('Adding match: ${matchData['teamA']} vs ${matchData['teamB']}');
          final now = DateTime.now();
          await db.collection('matches').add({
            'teamA': matchData['teamA'],
            'teamB': matchData['teamB'],
            'category': matchData['category'],
            'sport': matchData['sport'],
            'countryId': englandId,
            'championId': premierLeagueId,
            'dateTimeStart': Timestamp.fromDate(now.add(const Duration(days: 1))),
            'dateTimeEnd': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 2))),
            'odds': {
              'match_winner': {
                'teamA': 2.5,
                'draw': 3.2,
                'teamB': 2.8,
              }
            },
            'visible': true,
            'status': 'open',
            'searchableText': '${matchData['teamA']!.toLowerCase()} ${matchData['teamB']!.toLowerCase()} ${matchData['category']!.toLowerCase()} ${matchData['sport']!.toLowerCase()}',
          });
          matchesAdded++;
        } else {
          print('Match already exists: ${matchData['teamA']} vs ${matchData['teamB']}');
        }
      }
      print('Added $matchesAdded new matches');

      print('Test data added successfully!');
    } catch (e) {
      print('Error adding test data: $e');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Quick test data addition (without queries)
  Future<void> addQuickTestData() async {
    try {
      print('Adding quick test data...');
      
      // Add England country directly
      final englandRef = await db.collection('countries').add({
        'name': 'England',
        'code': 'EN',
        'searchableText': 'england',
      });
      print('England added with ID: ${englandRef.id}');
      
      // Add Premier League champion
      final premierLeagueRef = await db.collection('champions').add({
        'name': 'Premier League',
        'countryId': englandRef.id,
        'countryName': 'England',
        'sport': 'Football',
        'searchableText': 'premier league',
      });
      print('Premier League added with ID: ${premierLeagueRef.id}');
      
      // Add just a few key teams
      final keyTeams = ['Manchester United', 'Manchester City', 'Liverpool', 'Chelsea'];
      for (final teamName in keyTeams) {
        await db.collection('teams').add({
          'name': teamName,
          'countryId': englandRef.id,
          'championId': premierLeagueRef.id,
          'sport': 'Football',
          'searchableText': teamName.toLowerCase(),
        });
        print('Added team: $teamName');
      }
      
      // Add one test match
      final now = DateTime.now();
      await db.collection('matches').add({
        'teamA': 'Manchester United',
        'teamB': 'Liverpool',
        'category': 'Premier League',
        'sport': 'Football',
        'countryId': englandRef.id,
        'championId': premierLeagueRef.id,
        'dateTimeStart': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'dateTimeEnd': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 2))),
        'odds': {
          'match_winner': {
            'teamA': 2.5,
            'draw': 3.2,
            'teamB': 2.8,
          }
        },
        'visible': true,
        'status': 'open',
        'searchableText': 'manchester united liverpool premier league football',
      });
      print('Added match: Manchester United vs Liverpool');
      
      print('Quick test data added successfully!');
    } catch (e) {
      print('Error adding quick test data: $e');
      rethrow;
    }
  }
} 