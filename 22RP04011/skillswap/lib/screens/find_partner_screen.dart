import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_list_screen.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class FindPartnerScreen extends StatefulWidget {
  const FindPartnerScreen({super.key});

  @override
  State<FindPartnerScreen> createState() => _FindPartnerScreenState();
}

class _FindPartnerScreenState extends State<FindPartnerScreen> {
  String? _selectedLearn;
  String? _selectedTeach;
  List<String> _skills = [];
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Most Recent';
  List<String> _popularSkills = [];
  String? _selectedLocation;
  double? _selectedRating;
  List<String> _locations = [];
  final List<double> _ratings = [5, 4, 3, 2, 1];
  List<UserDetails> _partners = [];

  @override
  void initState() {
    super.initState();
    _fetchSkills();
    _fetchMatches();
    _fetchPopularSkills();
    _fetchLocations();
    _loadPartners();
  }

  Future<void> _fetchSkills() async {
    setState(() => _isLoading = true);
    try {
      final users = await FirebaseFirestore.instance.collection('users').get();
      final Set<String> skillsSet = {};
      for (var doc in users.docs) {
        final data = doc.data();
        if (data['skillsOffered'] is List) {
          skillsSet.addAll(List<String>.from(data['skillsOffered']));
        } else if (data['skillsOffered'] is String) {
          skillsSet
              .addAll(data['skillsOffered'].split(',').map((e) => e.trim()));
        }
        if (data['skillsToLearn'] is List) {
          skillsSet.addAll(List<String>.from(data['skillsToLearn']));
        } else if (data['skillsToLearn'] is String) {
          skillsSet
              .addAll(data['skillsToLearn'].split(',').map((e) => e.trim()));
        }
      }
      setState(() {
        _skills = skillsSet.where((s) => s.isNotEmpty).toList()..sort();
        if (_skills.isNotEmpty) {
          _selectedLearn ??= _skills.first;
          _selectedTeach ??= _skills.length > 1 ? _skills[1] : _skills.first;
        }
      });
    } catch (e) {
      setState(() => _error = 'Failed to load skills.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMatches() async {
    setState(() => _isRefreshing = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final users = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> matches = [];
      for (var doc in users.docs) {
        if (currentUser != null && doc.id == currentUser.uid)
          continue; // Exclude self
        final data = doc.data();
        final List<String> offered = data['skillsOffered'] is List
            ? List<String>.from(data['skillsOffered'])
            : (data['skillsOffered'] ?? '')
                .toString()
                .split(',')
                .map((e) => e.trim())
                .toList();
        final List<String> toLearn = data['skillsToLearn'] is List
            ? List<String>.from(data['skillsToLearn'])
            : (data['skillsToLearn'] ?? '')
                .toString()
                .split(',')
                .map((e) => e.trim())
                .toList();
        // Correct matching logic:
        // User must OFFER the skill I want to LEARN, and WANT TO LEARN the skill I can TEACH
        if (_selectedLearn != null && _selectedTeach != null) {
          if (offered.contains(_selectedLearn) &&
              toLearn.contains(_selectedTeach)) {
            matches.add(data);
          }
        } else {
          matches.add(data);
        }
      }
      setState(() {
        _matches = matches;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load matches.');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _fetchPopularSkills() async {
    // Example: Get top 5 most common skills
    final users = await FirebaseFirestore.instance.collection('users').get();
    final Map<String, int> skillCounts = {};
    for (var doc in users.docs) {
      final data = doc.data();
      for (var skill in (data['skillsOffered'] ?? [])) {
        skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
      }
    }
    final sorted = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _popularSkills = sorted.take(5).map((e) => e.key).toList();
    });
  }

  Future<void> _fetchLocations() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    final Set<String> locationsSet = {};
    for (var doc in users.docs) {
      final data = doc.data();
      if (data['location'] != null && data['location'].toString().isNotEmpty) {
        locationsSet.add(data['location'].toString());
      }
    }
    setState(() {
      _locations = locationsSet.toList()..sort();
    });
  }

  void _onFindMatches() async {
    await _fetchMatches();
    if (mounted && _filteredMatches().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches found for your selection.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matches updated!')),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  void _onClearFilters() {
    setState(() {
      _selectedLearn = null;
      _selectedTeach = null;
      _searchQuery = '';
      _sortBy = 'Most Recent';
      _searchController.clear();
    });
    _fetchMatches();
  }

  Future<void> _onRefresh() async {
    await _fetchSkills();
    await _fetchMatches();
    await _fetchPopularSkills();
  }

  List<Map<String, dynamic>> _filteredMatches() {
    List<Map<String, dynamic>> filtered = _matches.where((m) {
      final name = (m['fullName'] ?? '').toString().toLowerCase();
      final skills =
          ((m['skillsOffered'] ?? []) as List).join(',').toLowerCase();
      final location = (m['location'] ?? '').toString();
      final rating = (m['ratings'] ?? 0).toDouble();
      final matchesSearch =
          name.contains(_searchQuery) || skills.contains(_searchQuery);
      final matchesLocation =
          _selectedLocation == null || location == _selectedLocation;
      final matchesRating =
          _selectedRating == null || rating >= _selectedRating!;
      return matchesSearch && matchesLocation && matchesRating;
    }).toList();
    if (_sortBy == 'Most Active') {
      filtered.sort((a, b) => ((b['lastActive'] ?? 0) as int)
          .compareTo((a['lastActive'] ?? 0) as int));
    }
    return filtered;
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();
      final users =
          snapshot.docs.map((doc) => UserDetails.fromFirestore(doc)).toList();
      setState(() {
        _partners = users;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load partners.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserDetails> get _filteredPartners {
    if (_searchQuery.isEmpty) return _partners;
    return _partners
        .where((u) =>
            u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.skillsOffered
                .join(',')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.blue[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'Find Skill Partner',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdowns with labels
                const SizedBox(height: 8),
                const Text('What do you want to learn?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedLearn,
                  items: _skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedLearn = val);
                    _fetchMatches();
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('What can you teach?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTeach,
                  items: _skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedTeach = val);
                    _fetchMatches();
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isRefreshing ? null : _onFindMatches,
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Find Matches',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('Suggested Matches',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(_error!,
                                style: TextStyle(color: Colors.red)))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isTablet = constraints.maxWidth > 600;
                              final matches = _filteredMatches();
                              if (matches.isEmpty) {
                                return Center(
                                    child: Text('No partners found.',
                                        style: TextStyle(color: Colors.grey)));
                              }
                              if (isTablet) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.8,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: matches.length,
                                  itemBuilder: (context, i) => AnimatedOpacity(
                                    opacity: 1.0,
                                    duration:
                                        Duration(milliseconds: 300 + i * 50),
                                    child: _matchCard(matches[i]),
                                  ),
                                );
                              } else {
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: matches.length,
                                  itemBuilder: (context, i) => AnimatedOpacity(
                                    opacity: 1.0,
                                    duration:
                                        Duration(milliseconds: 300 + i * 50),
                                    child: _matchCard(matches[i]),
                                  ),
                                );
                              }
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _matchCard(Map<String, dynamic> user) {
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
    final String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';
    final bool isOnline = user['isOnline'] == true;
    final bool isHighlyRated = rating >= 4.8;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[200],
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(initials,
                                style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isHighlyRated)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
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
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: skills.map((s) => _skillChip(s)).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser == null) return;
                                final otherUserId = user['uid'] ?? user['id'];
                                if (otherUserId == null) return;
                                final chatQuery = await FirebaseFirestore
                                    .instance
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
                                  final chatDoc = await FirebaseFirestore
                                      .instance
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      receiverId: otherUserId,
                                      receiverName: user['fullName'] ?? 'User',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Connect',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => _showProfileModal(user),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue[700]!, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor: Colors.blue[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('View Profile',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
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
        return Center(
          child: Container(
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
          ),
        );
      },
    );
  }

  static Widget _skillChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide.none,
    );
  }

  Widget _buildPartnerCard(UserDetails user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              backgroundImage:
                  user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? Text(user.fullName.isNotEmpty ? user.fullName[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(user.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: user.skillsOffered
                        .take(3)
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      receiverId: user.uid,
                      receiverName: user.fullName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
