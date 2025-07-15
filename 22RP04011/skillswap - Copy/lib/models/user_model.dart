import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String uid;
  final String fullName;
  final String email;
  final List<String> skillsOffered;
  final List<String> skillsToLearn;
  final String phone;
  final String availability;
  final String location;
  final bool isOnline;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final DateTime? lastTokenUpdate;
  final int? lastTabIndex;
  final String? subscriptionStatus;
  final String? subscriptionType;
  final DateTime? subscriptionExpiry;

  UserDetails({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.skillsOffered,
    required this.skillsToLearn,
    required this.phone,
    required this.availability,
    required this.location,
    required this.isOnline,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.lastTokenUpdate,
    this.lastTabIndex,
    this.subscriptionStatus,
    this.subscriptionType,
    this.subscriptionExpiry,
  });

  factory UserDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDetails(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      skillsOffered: List<String>.from(data['skillsOffered'] ?? []),
      skillsToLearn: List<String>.from(data['skillsToLearn'] ?? []),
      phone: data['phone'] ?? '',
      availability: data['availability'] ?? 'Available',
      location: data['location'] ?? '',
      isOnline: data['isOnline'] ?? false,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
      lastTokenUpdate: (data['lastTokenUpdate'] as Timestamp?)?.toDate(),
      lastTabIndex: data['lastTabIndex'],
      subscriptionStatus: data['subscriptionStatus'],
      subscriptionType: data['subscriptionType'],
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'skillsOffered': skillsOffered,
      'skillsToLearn': skillsToLearn,
      'phone': phone,
      'availability': availability,
      'location': location,
      'isOnline': isOnline,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken,
      'lastTokenUpdate':
          lastTokenUpdate != null ? Timestamp.fromDate(lastTokenUpdate!) : null,
      'lastTabIndex': lastTabIndex,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionType': subscriptionType,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
    };
  }

  // Ensure all required subcollections exist for a user
  static Future<void> ensureUserSubcollections(String uid) async {
    final firestore = FirebaseFirestore.instance;
    // Create a dummy doc in each subcollection if it doesn't exist
    final badgesRef =
        firestore.collection('users').doc(uid).collection('badges').doc('init');
    final skillsRef =
        firestore.collection('users').doc(uid).collection('skills').doc('init');
    final activityRef = firestore
        .collection('users')
        .doc(uid)
        .collection('activity')
        .doc('init');
    await Future.wait([
      badgesRef.set({'init': true}, SetOptions(merge: true)),
      skillsRef.set({'init': true}, SetOptions(merge: true)),
      activityRef.set({'init': true}, SetOptions(merge: true)),
    ]);
  }

  UserDetails copyWith({
    String? fullName,
    String? email,
    List<String>? skillsOffered,
    List<String>? skillsToLearn,
    String? phone,
    String? availability,
    String? location,
    bool? isOnline,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    DateTime? lastTokenUpdate,
    int? lastTabIndex,
    String? subscriptionStatus,
    String? subscriptionType,
    DateTime? subscriptionExpiry,
  }) {
    return UserDetails(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      phone: phone ?? this.phone,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      lastTabIndex: lastTabIndex ?? this.lastTabIndex,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    );
  }
}
