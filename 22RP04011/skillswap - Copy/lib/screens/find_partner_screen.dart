import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class FindPartnerScreen extends StatefulWidget {
  const FindPartnerScreen({super.key});

  @override
  State<FindPartnerScreen> createState() => _FindPartnerScreenState();
}

class _FindPartnerScreenState extends State<FindPartnerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<String> _skillsToLearn = [];
  List<String> _skillsOffered = [];
  String? _selectedLearnSkill;
  String? _selectedTeachSkill;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchAllSkills();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    final subscriptionStatus = data?['subscriptionStatus'] as String?;
    final subscriptionExpiry = data?['subscriptionExpiry'] as Timestamp?;
    bool hasActiveSubscription = false;
    if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
      final expiryDate = subscriptionExpiry.toDate();
      hasActiveSubscription = expiryDate.isAfter(DateTime.now());
    }
    if (!hasActiveSubscription && mounted) {
      Navigator.pushReplacementNamed(context, '/subscription');
    }
  }

  Future<void> _fetchAllSkills() async {
    setState(() => _isLoading = true);
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final Set<String> learnSet = {};
    final Set<String> offerSet = {};
    for (var doc in usersSnap.docs) {
      final data = doc.data();
      if (data['skillsToLearn'] is List) {
        for (var s in data['skillsToLearn']) {
          if (s is String && s.isNotEmpty) learnSet.add(s);
        }
      }
      if (data['skillsOffered'] is List) {
        for (var s in data['skillsOffered']) {
          if (s is String && s.isNotEmpty) offerSet.add(s);
        }
      }
    }
    setState(() {
      _skillsToLearn = learnSet.toList()..sort();
      _skillsOffered = offerSet.toList()..sort();
      _isLoading = false;
    });
  }

  Future<void> _findMatches() async {
    if (_selectedLearnSkill == null || _selectedTeachSkill == null) return;
    setState(() => _isLoading = true);
    final currentUser = _auth.currentUser;
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('skillsOffered', arrayContains: _selectedTeachSkill)
        .get();

    final matches = <Map<String, dynamic>>[];
    for (var doc in usersSnap.docs) {
      if (doc.id == currentUser?.uid) continue; // Exclude self
      final data = doc.data();
      final skillsToLearn = List<String>.from(data['skillsToLearn'] ?? []);
      if (skillsToLearn.contains(_selectedLearnSkill)) {
        matches.add({
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'location': data['location'] ?? '',
          'availability': data['availability'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'skillsOffered': data['skillsOffered'] ?? [],
          'skillsToLearn': data['skillsToLearn'] ?? [],
          'subscriptionStatus': data['subscriptionStatus'] ?? '',
          'subscriptionType': data['subscriptionType'] ?? '',
          'subscriptionExpiry': data['subscriptionExpiry'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'photoUrl': data['photoUrl'],
          'userId': doc.id,
        });
      }
    }
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Skill Partner'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'What do you want to learn?',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLearnSkill,
                items: _skillsToLearn
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLearnSkill = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'What can you teach?',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTeachSkill,
                items: _skillsOffered
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTeachSkill = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _findMatches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Find Matches',
                          style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Suggested Matches',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _matches.isEmpty
                        ? const Center(child: Text('No matches found.'))
                        : ListView.builder(
                            itemCount: _matches.length,
                            itemBuilder: (context, i) {
                              final m = _matches[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      m['photoUrl'] != null &&
                                              (m['photoUrl'] as String)
                                                  .isNotEmpty
                                          ? CircleAvatar(
                                              backgroundImage:
                                                  NetworkImage(m['photoUrl']),
                                              radius: 32)
                                          : const CircleAvatar(
                                              child: Icon(Icons.person),
                                              radius: 32),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(m['fullName'],
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18)),
                                                const SizedBox(width: 8),
                                                if (m['isOnline'] == true)
                                                  const Icon(Icons.circle,
                                                      color: Colors.green,
                                                      size: 12),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Email: ${m['email']}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            Text('Phone: ${m['phone']}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            Text('Location: ${m['location']}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            Text(
                                                'Availability: ${m['availability']}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Skills Offered: ${(m['skillsOffered'] as List).join(", ")}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            Text(
                                                'Skills To Learn: ${(m['skillsToLearn'] as List).join(", ")}',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Subscription: ${m['subscriptionStatus']} (${m['subscriptionType']})',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            if (m['subscriptionExpiry'] != null)
                                              Text(
                                                  'Expiry: ${m['subscriptionExpiry'] is Timestamp ? (m['subscriptionExpiry'] as Timestamp).toDate().toString().split(".")[0] : m['subscriptionExpiry'].toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Created: ${m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate().toString().split(".")[0] : m['createdAt'].toString()}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey)),
                                            Text(
                                                'Updated: ${m['updatedAt'] is Timestamp ? (m['updatedAt'] as Timestamp).toDate().toString().split(".")[0] : m['updatedAt'].toString()}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          // TODO: Implement connect action
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Connect'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchCard(Map<String, dynamic> user, bool isTablet) {
    final String name = user['fullName'] ?? 'Unknown';
    final String role = user['role'] ??
        (user['skillsOffered'] is List && user['skillsOffered'].isNotEmpty
            ? user['skillsOffered'][0]
            : 'Skill Partner');
    final double rating =
        (user['rating'] is num) ? user['rating'].toDouble() : 4.5;
    final List<String> skillsOffered = user['skillsOffered'] is List
        ? List<String>.from(user['skillsOffered'])
        : [];
    final List<String> skillsToLearn = user['skillsToLearn'] is List
        ? List<String>.from(user['skillsToLearn'])
        : [];
    final String? photoUrl = user['photoURL'];
    final String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';
    final bool isOnline = user['isOnline'] == true;
    final bool isHighlyRated = rating >= 4.8;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isSelf = currentUser != null && user['uid'] == currentUser.uid;
    const bool alreadyConnected = false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isTablet ? 40 : 30,
                      backgroundColor: Colors.blue[200],
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(initials,
                              style: TextStyle(
                                  fontSize: isTablet ? 28 : 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: isTablet ? 18 : 14,
                          height: isTablet ? 18 : 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 22 : 17),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHighlyRated)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10 : 7,
                                  vertical: isTablet ? 5 : 3),
                              decoration: BoxDecoration(
                                color: Colors.amber[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Top Rated',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 6 : 2),
                      Text(
                        role,
                        style: TextStyle(
                            fontSize: isTablet ? 16 : 13,
                            color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 10 : 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 14 : 10),
            if (skillsOffered.isNotEmpty) ...[
              Text('Skills Offered:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 13)),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: skillsOffered
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _skillChip(s),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (skillsToLearn.isNotEmpty) ...[
              Text('Skills To Learn:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 13)),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: skillsToLearn
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _skillChip(s),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(height: isTablet ? 18 : 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View Profile'),
                    onPressed: () => _showProfileModal(user),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[700]!, width: 1.2),
                      foregroundColor: Colors.blue[800],
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: isTablet ? 14 : 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyConnected || isSelf
                          ? Colors.grey[400]
                          : Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: isTablet ? 14 : 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: (alreadyConnected || isSelf)
                        ? null
                        : () async {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;
                            final otherUserId = user['uid'] ?? user['id'];
                            if (otherUserId == null) return;

                            try {
                              final chatQuery = await FirebaseFirestore.instance
                                  .collection('chats')
                                  .where('participants',
                                      arrayContains: currentUser.uid)
                                  .get();

                              String? chatId;
                              for (var doc in chatQuery.docs) {
                                final participants = List<String>.from(
                                    doc['participants'] ?? []);
                                if (participants.contains(otherUserId)) {
                                  chatId = doc.id;
                                  break;
                                }
                              }

                              if (chatId == null) {
                                final chatDoc = await FirebaseFirestore.instance
                                    .collection('chats')
                                    .add({
                                  'participants': [
                                    currentUser.uid,
                                    otherUserId
                                  ],
                                  'lastMessage': '',
                                  'lastTimestamp': DateTime.now(),
                                });
                                chatId = chatDoc.id;
                              }

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      receiverId: otherUserId,
                                      receiverName: user['fullName'] ?? 'User',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to start chat: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(
                      alreadyConnected
                          ? 'Connected'
                          : isSelf
                              ? 'You'
                              : 'Connect',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileModal(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final String name = user['fullName'] ?? 'Unknown';
        final String role = user['role'] ??
            (user['skillsOffered'] is List && user['skillsOffered'].isNotEmpty
                ? user['skillsOffered'][0]
                : 'Skill Partner');
        final double rating =
            (user['rating'] is num) ? user['rating'].toDouble() : 4.5;
        final List<String> skills = user['skillsOffered'] is List
            ? List<String>.from(user['skillsOffered'])
            : [];
        final String? photoUrl = user['photoURL'];
        final String location = user['location'] ?? 'Unknown';
        final String bio = user['bio'] ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue[200],
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 4),
                Text(role,
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Location: $location',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(bio, style: const TextStyle(fontSize: 15)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: skills.map((s) => _skillChip(s)).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _skillChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide.none,
    );
  }
}
