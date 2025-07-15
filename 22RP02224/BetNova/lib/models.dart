import 'package:cloud_firestore/cloud_firestore.dart';

// Country Model
class Country {
  final String id;
  final String name;
  final String code;

  Country({
    required this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'searchableText': name.toLowerCase(),
    };
  }

  factory Country.fromMap(String id, Map<String, dynamic> map) {
    return Country(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
    );
  }
}

// Team Model
class Team {
  final String id;
  final String name;
  final String countryId;
  final String sport;
  final String? logoUrl;

  Team({
    required this.id,
    required this.name,
    required this.countryId,
    required this.sport,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'countryId': countryId,
      'sport': sport,
      'logoUrl': logoUrl,
      'searchableText': name.toLowerCase(),
    };
  }

  factory Team.fromMap(String id, Map<String, dynamic> map) {
    return Team(
      id: id,
      name: map['name'] ?? '',
      countryId: map['countryId'] ?? '',
      sport: map['sport'] ?? 'Football',
      logoUrl: map['logoUrl'],
    );
  }
}

// Match Model
class Match {
  final String id;
  final String sport;
  final String countryId;
  final String championId;
  final String teamA;
  final String teamB;
  final DateTime dateTimeStart;
  final DateTime dateTimeEnd;
  final Map<String, dynamic> odds;
  final String category;
  final bool visible;
  final String? result;
  final String status; // open, closed, live
  final String? marketingLabel; // Trending, Last Minute, Editor's Pick

  Match({
    required this.id,
    required this.sport,
    required this.countryId,
    required this.championId,
    required this.teamA,
    required this.teamB,
    required this.dateTimeStart,
    required this.dateTimeEnd,
    required this.odds,
    required this.category,
    required this.visible,
    this.result,
    required this.status,
    this.marketingLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'sport': sport,
      'countryId': countryId,
      'championId': championId,
      'teamA': teamA,
      'teamB': teamB,
      'dateTimeStart': Timestamp.fromDate(dateTimeStart),
      'dateTimeEnd': Timestamp.fromDate(dateTimeEnd),
      'odds': odds,
      'category': category,
      'visible': visible,
      'result': result,
      'status': status,
      'marketingLabel': marketingLabel,
      'searchableText': '${teamA.toLowerCase()} ${teamB.toLowerCase()} ${category.toLowerCase()} ${sport.toLowerCase()}',
    };
  }

  factory Match.fromMap(String id, Map<String, dynamic> map) {
    return Match(
      id: id,
      sport: map['sport'] ?? '',
      countryId: map['countryId'] ?? '',
      championId: map['championId'] ?? '',
      teamA: map['teamA'] ?? '',
      teamB: map['teamB'] ?? '',
      dateTimeStart: (map['dateTimeStart'] as Timestamp).toDate(),
      dateTimeEnd: (map['dateTimeEnd'] as Timestamp).toDate(),
      odds: map['odds'] is Map ? Map<String, dynamic>.from(map['odds']) : {},
      category: map['category'] ?? '',
      visible: map['visible'] ?? false,
      result: map['result'],
      status: map['status'] ?? 'open',
      marketingLabel: map['marketingLabel'],
    );
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => dateTimeStart.isAfter(DateTime.now()) && status == 'open';
  bool get isExpired => dateTimeEnd.isBefore(DateTime.now());
  bool get canBet => visible && !isExpired && status == 'open';
}

// Bet Model
class Bet {
  final String id;
  final String userId;
  final String matchId;
  final String betType; // e.g., 'match_winner', 'over_under_2_5'
  final String predicted; // e.g., 'teamA', 'over'
  final String status; // pending, approved, won, lost
  final String? result; // won, lost
  final double? amount;
  final DateTime timestamp;

  Bet({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.betType,
    required this.predicted,
    required this.status,
    this.result,
    this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'matchId': matchId,
      'betType': betType,
      'predicted': predicted,
      'status': status,
      'result': result,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Bet.fromMap(String id, Map<String, dynamic> map) {
    return Bet(
      id: id,
      userId: map['userId'] ?? '',
      matchId: map['matchId'] ?? '',
      betType: map['betType'] ?? 'match_winner', // Default for older bets
      predicted: map['predicted'] ?? '',
      status: map['status'] ?? 'pending',
      result: map['result'],
      amount: map['amount']?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isWon => status == 'won';
  bool get isLost => status == 'lost';
}

// User Model
class User {
  final String id;
  final String name;
  final String? phone;
  final String role; // user, admin
  final DateTime joinedAt;
  final double? balance;
  final String subscriptionTier; // 'free', 'premium'
  final DateTime? subscriptionExpiry;
  final bool isPremiumActive;

  User({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    required this.joinedAt,
    this.balance,
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.isPremiumActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'balance': balance,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry != null ? Timestamp.fromDate(subscriptionExpiry!) : null,
      'isPremiumActive': isPremiumActive,
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    final subscriptionExpiry = map['subscriptionExpiry'] as Timestamp?;
    final isPremiumActive = map['isPremiumActive'] as bool? ?? false;
    
    return User(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'user',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      balance: map['balance']?.toDouble(),
      subscriptionTier: map['subscriptionTier'] ?? 'free',
      subscriptionExpiry: subscriptionExpiry?.toDate(),
      isPremiumActive: isPremiumActive,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPremium => subscriptionTier == 'premium' && isPremiumActive;
  bool get hasActiveSubscription => isPremium && (subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now()));
}

// Champion/League Model
class Champion {
  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String sport;

  Champion({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
    required this.sport,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'countryId': countryId,
      'countryName': countryName,
      'sport': sport,
      'searchableText': name.toLowerCase(),
    };
  }

  factory Champion.fromMap(String id, Map<String, dynamic> map) {
    return Champion(
      id: id,
      name: map['name'] ?? '',
      countryId: map['countryId'] ?? '',
      countryName: map['countryName'] ?? '',
      sport: map['sport'] ?? 'Football',
    );
  }
} 