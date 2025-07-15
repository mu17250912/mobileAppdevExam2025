import 'package:flutter/material.dart';
import '../models/internship.dart';
import '../services/internship_service.dart';
import 'internship_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../student_home_page.dart';

class BrowseInternshipsPage extends StatefulWidget {
  const BrowseInternshipsPage({Key? key}) : super(key: key);

  @override
  State<BrowseInternshipsPage> createState() => _BrowseInternshipsPageState();
}

class _BrowseInternshipsPageState extends State<BrowseInternshipsPage> {
  final InternshipService _internshipService = InternshipService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedLocation = 'All';
  String _selectedType = 'All';
  List<String> _selectedSkills = [];
  bool isUpgraded = false;
  
  final List<String> _locations = [
    'All',
    'Remote',
    'New York',
    'San Francisco',
    'London',
    'Toronto',
    'Mumbai',
    'Singapore',
  ];
  
  final List<String> _types = [
    'All',
    'Full-time',
    'Part-time',
    'Remote',
    'Hybrid',
  ];
  
  final List<String> _allSkills = [
    'Python',
    'JavaScript',
    'React',
    'Flutter',
    'Java',
    'C++',
    'Machine Learning',
    'Data Analysis',
    'UI/UX Design',
    'Marketing',
    'Sales',
    'Communication',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Internship>> _getInternships() {
    if (_searchController.text.isNotEmpty) {
      return _internshipService.searchInternships(_searchController.text);
    }
    
    String? location = _selectedLocation == 'All' ? null : _selectedLocation;
    String? type = _selectedType == 'All' ? null : _selectedType;
    List<String>? skills = _selectedSkills.isEmpty ? null : _selectedSkills;
    
    return _internshipService.filterInternships(
      location: location,
      type: type,
      skills: skills,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Internships'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLocation = 'All';
                  _selectedType = 'All';
                  _selectedSkills.clear();
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const StudentHomePage()),
              (route) => false,
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              backgroundImage: AssetImage('assets/images/logo.png'),
              child: Icon(Icons.school, color: Color(0xFF0D3B24), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Browse Internships',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D3B24),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search internships...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          
          if (_selectedLocation != 'All' || _selectedType != 'All' || _selectedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedLocation != 'All')
                    Chip(
                      label: Text('Location: $_selectedLocation'),
                      onDeleted: () {
                        setState(() {
                          _selectedLocation = 'All';
                        });
                      },
                    ),
                  if (_selectedType != 'All')
                    Chip(
                      label: Text('Type: $_selectedType'),
                      onDeleted: () {
                        setState(() {
                          _selectedType = 'All';
                        });
                      },
                    ),
                  ..._selectedSkills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _selectedSkills.remove(skill);
                      });
                    },
                  )),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<Internship>>(
              stream: _getInternships(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                final internships = snapshot.data ?? [];
                
                if (internships.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No internships found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: internships.length,
                  itemBuilder: (context, index) {
                    final internship = internships[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          internship.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              internship.companyName,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              internship.location,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    internship.type,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  internship.stipend,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (internship.skills.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: internship.skills.take(3).map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      skill,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          if (!isUpgraded) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Unlock Feature'),
                                content: const Text('Upgrade your account to unlock and view internship details.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isUpgraded = true;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Upgrade Now'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InternshipDetailPage(
                                  internship: internship,
                                ),
                              ),
                            );
                          }
                        },
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
  }
} 