import 'package:flutter/material.dart';
import 'partner_profile_screen.dart';

class FindPartnerScreen extends StatefulWidget {
  @override
  State<FindPartnerScreen> createState() => _FindPartnerScreenState();
}

class _FindPartnerScreenState extends State<FindPartnerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubject;
  Map<String, dynamic>? _selectedPartner;

  final List<Map<String, dynamic>> _partners = [
    {
      'name': 'Sarah Martinez',
      'status': 'Online • University of Rwanda',
      'match': 92,
      'subjects': ['Mathematics', 'Physics', 'Chemistry'],
      'sessions': 47,
      'rating': 4.9,
      'partners': 15,
      'university': 'University of Rwanda',
    },
    {
      'name': 'David Karim',
      'status': 'Away • KIST',
      'match': 85,
      'subjects': ['Math'],
      'sessions': 32,
      'rating': 4.7,
      'partners': 8,
      'university': 'KIST',
    },
    {
      'name': 'Amina Uwase',
      'status': 'Online • University of Kigali',
      'match': 88,
      'subjects': ['Biology', 'Chemistry'],
      'sessions': 28,
      'rating': 4.8,
      'partners': 10,
      'university': 'University of Kigali',
    },
    {
      'name': 'Jean Bosco',
      'status': 'Online • UNILAK',
      'match': 80,
      'subjects': ['Mathematics', 'ICT'],
      'sessions': 19,
      'rating': 4.5,
      'partners': 6,
      'university': 'UNILAK',
    },
    {
      'name': 'Claudine Iradukunda',
      'status': 'Away • University of Rwanda',
      'match': 78,
      'subjects': ['English', 'History'],
      'sessions': 22,
      'rating': 4.6,
      'partners': 7,
      'university': 'University of Rwanda',
    },
    {
      'name': 'Eric Niyonzima',
      'status': 'Online • KIST',
      'match': 90,
      'subjects': ['Physics', 'Math'],
      'sessions': 35,
      'rating': 4.9,
      'partners': 12,
      'university': 'KIST',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allSubjects {
    final set = <String>{};
    for (final p in _partners) {
      set.addAll((p['subjects'] as List).cast<String>());
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredPartners {
    final query = _searchQuery.toLowerCase();
    return _partners.where((partner) {
      final matchesSearch = query.isEmpty ||
        partner['name'].toLowerCase().contains(query) ||
        partner['status'].toLowerCase().contains(query) ||
        (partner['university']?.toLowerCase().contains(query) ?? false) ||
        (partner['subjects'] as List).any((s) => s.toLowerCase().contains(query));
      final matchesSubject = _selectedSubject == null ||
        (partner['subjects'] as List).contains(_selectedSubject);
      return matchesSearch && matchesSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text('Find Partner', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.music_note, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, subject, or university',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            SizedBox(height: 16),

            /// Subject Chips as Filters
            if (_allSubjects.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All'),
                      selected: _selectedSubject == null,
                      onSelected: (_) {
                        setState(() => _selectedSubject = null);
                      },
                      selectedColor: Colors.blueGrey[400],
                      backgroundColor: Colors.blueGrey[100],
                    ),
                    ..._allSubjects.map((subject) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(subject),
                        selected: _selectedSubject == subject,
                        onSelected: (_) {
                          setState(() => _selectedSubject = subject);
                        },
                        selectedColor: Colors.blueGrey[400],
                        backgroundColor: Colors.blueGrey[200],
                      ),
                    )),
                  ],
                ),
              ),

            SizedBox(height: 20),

            /// List of Partners
            Expanded(
              child: ListView(
                children: _filteredPartners.map((partner) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPartner = partner;
                    });
                  },
                  child: _partnerCard(context,
                    name: partner['name'],
                    status: partner['status'],
                    match: partner['match'],
                    subjects: List<String>.from(partner['subjects']),
                    sessions: partner['sessions'],
                    rating: partner['rating'],
                    partners: partner['partners'],
                    selected: _selectedPartner == partner,
                  ),
                )).toList(),
              ),
            ),
            if (_selectedPartner != null && _selectedSubject != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/join-session',
                        arguments: {
                          ..._selectedPartner!,
                          'subject': _selectedSubject,
                        },
                      );
                    },
                    child: Text('Join'),
                  ),
                ),
              ),
          ],
        ),
      ),
      /// Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Already here
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/update-profile');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/create-session');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Partner'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Session'),
        ],
      ),
    );
  }

  /// Filter Chip Style
  Widget _filterButton(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 15)),
    );
  }

  /// Partner Card Widget
  Widget _partnerCard(
    BuildContext context, // Add context parameter
    {
      required String name,
      required String status,
      required int match,
      required List<String> subjects,
      required int sessions,
      required double rating,
      required int partners,
      bool selected = false,
    }
  ) {
    return Card(
      color: selected ? Colors.blue[50] : Colors.white,
      elevation: selected ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status),
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerProfileScreen(partner: {
                'name': name,
                'status': status,
                'subjects': subjects,
                'sessions': sessions,
                'rating': rating,
                'partners': partners,
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _subjectChip(String subject) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(subject, style: TextStyle(fontSize: 14)),
    );
  }

  Widget _actionButton(String label, {VoidCallback? onPressed}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[400],
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
