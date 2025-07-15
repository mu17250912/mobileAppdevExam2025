import 'package:flutter/material.dart';
import 'models.dart';
import 'firestore_service.dart';

class AdminCountryTeamManagement extends StatefulWidget {
  const AdminCountryTeamManagement({super.key});

  @override
  State<AdminCountryTeamManagement> createState() => _AdminCountryTeamManagementState();
}

class _AdminCountryTeamManagementState extends State<AdminCountryTeamManagement> {
  final FirestoreService _service = FirestoreService();
  final _countryNameController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _teamLogoUrlController = TextEditingController();
  String? _selectedCountryId;
  String _selectedSport = 'Football';
  String? _selectedChampionId;

  final List<String> _sports = ['Football', 'Basketball', 'Volleyball'];

  @override
  void dispose() {
    _countryNameController.dispose();
    _countryCodeController.dispose();
    _teamNameController.dispose();
    _teamLogoUrlController.dispose();
    super.dispose();
  }

  void _showAddCountryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Country'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _countryNameController,
              decoration: const InputDecoration(
                labelText: 'Country Name',
                hintText: 'e.g. Rwanda',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryCodeController,
              decoration: const InputDecoration(
                labelText: 'Country Code',
                hintText: 'e.g. RWA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _countryNameController.text.trim();
              final code = _countryCodeController.text.trim().toUpperCase();
              if (name.isNotEmpty && code.isNotEmpty) {
                final exists = await _service.countryExists(name: name, code: code);
                if (exists) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Country with this name or code already exists!'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }
                final country = Country(id: '', name: name, code: code);
                await _service.addCountry(country);
                _countryNameController.clear();
                _countryCodeController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTeamDialog() {
    if (_selectedCountryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSport,
              items: _sports.map((sport) {
                return DropdownMenuItem(
                  value: sport,
                  child: Text(sport),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSport = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Sport',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g. Rayon Sports',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamLogoUrlController,
              decoration: const InputDecoration(
                labelText: 'Team Logo URL (Optional)',
                hintText: 'https://example.com/logo.png',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_teamNameController.text.isNotEmpty && _selectedCountryId != null) {
                final team = Team(
                  id: '',
                  name: _teamNameController.text.trim(),
                  countryId: _selectedCountryId!,
                  sport: _selectedSport,
                  logoUrl: _teamLogoUrlController.text.isEmpty ? null : _teamLogoUrlController.text.trim(),
                );
                await _service.addTeam(team);
                _teamNameController.clear();
                _teamLogoUrlController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCountryDialog(Country country) {
    _countryNameController.text = country.name;
    _countryCodeController.text = country.code;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Country'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _countryNameController,
              decoration: const InputDecoration(labelText: 'Country Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryCodeController,
              decoration: const InputDecoration(labelText: 'Country Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_countryNameController.text.isNotEmpty && _countryCodeController.text.isNotEmpty) {
                await _service.updateCountry(country.id, {
                  'name': _countryNameController.text.trim(),
                  'code': _countryCodeController.text.trim().toUpperCase(),
                });
                _countryNameController.clear();
                _countryCodeController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCountry(String countryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this country?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteCountry(countryId);
    }
  }

  void _showEditTeamDialog(Team team) {
    _teamNameController.text = team.name;
    _teamLogoUrlController.text = team.logoUrl ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamLogoUrlController,
              decoration: const InputDecoration(labelText: 'Team Logo URL (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_teamNameController.text.isNotEmpty) {
                await _service.updateTeam(team.id, {
                  'name': _teamNameController.text.trim(),
                  'logoUrl': _teamLogoUrlController.text.trim(),
                });
                _teamNameController.clear();
                _teamLogoUrlController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTeam(String teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteTeam(teamId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Country & Team Management'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Countries'),
              Tab(text: 'Teams'),
            ],
            indicatorColor: Colors.lime,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildCountriesTab(),
                  _buildTeamsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (fabContext) => FloatingActionButton(
            onPressed: () {
              if (DefaultTabController.of(fabContext).index == 0) {
                _showAddCountryDialog();
              } else {
                _showAddTeamDialog();
              }
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildCountriesTab() {
    return Container(
      color: Colors.grey[900],
      child: StreamBuilder<List<Country>>(
        stream: _service.getCountries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No countries added yet', style: TextStyle(color: Colors.white)),
            );
          }
          final countries = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  title: Text(country.name, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.lime),
                        onPressed: () => _showEditCountryDialog(country),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteCountry(country.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamsTab() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Navigation Summary
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.navigation, color: Colors.green[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Current Navigation:',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNavigationSummary(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help_outline, color: Colors.grey[400], size: 20),
                  onPressed: _showNavigationHelp,
                  tooltip: 'Navigation Help',
                ),
              ],
            ),
          ),

          // Enhanced Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔍 Team Navigation & Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Country Selection
                StreamBuilder<List<Country>>(
                  stream: _service.getCountries(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }
                    final countries = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedCountryId,
                      decoration: const InputDecoration(
                        labelText: '🌍 Select Country',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                      ),
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(color: Colors.white),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('🌍 All Countries', style: TextStyle(color: Colors.white70)),
                        ),
                        ...countries.map((country) => DropdownMenuItem<String>(
                          value: country.id,
                          child: Row(
                            children: [
                              Text('🏳️ ${country.name}', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCountryId = value;
                          _selectedChampionId = null; // Reset champion when country changes
                        });
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Sport Filter
                DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(
                    labelText: '⚽ Select Sport',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  items: _sports.map((sport) {
                    String icon = '⚽';
                    if (sport == 'Basketball') icon = '🏀';
                    if (sport == 'Volleyball') icon = '🏐';
                    
                    return DropdownMenuItem(
                      value: sport,
                      child: Text('$icon $sport', style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSport = value!;
                      _selectedChampionId = null; // Reset champion when sport changes
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Champion/League Selection (if country and sport are selected)
                if (_selectedCountryId != null)
                  StreamBuilder<List<Champion>>(
                    stream: _service.getChampionsByCountry(_selectedCountryId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final champions = snapshot.data!.where((c) => c.sport == _selectedSport).toList();
                      if (champions.isEmpty) return const SizedBox.shrink();
                      
                      return DropdownButtonFormField<String>(
                        value: _selectedChampionId,
                        decoration: const InputDecoration(
                          labelText: '🏆 Select League/Championship',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                        ),
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('🏆 All Leagues', style: TextStyle(color: Colors.white70)),
                          ),
                          ...champions.map((champion) => DropdownMenuItem<String>(
                            value: champion.id,
                            child: Text('🏆 ${champion.name}', style: const TextStyle(color: Colors.white)),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedChampionId = value;
                          });
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          // Teams List with Enhanced Display
          Expanded(
            child: StreamBuilder<List<Team>>(
              stream: _getFilteredTeamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No teams found',
                          style: TextStyle(color: Colors.grey[400], fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or add new teams',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teamsByCountry.length,
                  itemBuilder: (context, index) {
                    final countryId = teamsByCountry.keys.elementAt(index);
                    final countryTeams = teamsByCountry[countryId]!;
                    
                    return FutureBuilder<Country?>(
                      future: _service.getCountry(countryId),
                      builder: (context, countrySnapshot) {
                        final countryName = countrySnapshot.data?.name ?? 'Unknown Country';
                        
                        return Card(
                          color: Colors.grey[850],
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: const Icon(Icons.flag, color: Colors.green),
                            title: Text(
                              '🏳️ $countryName (${countryTeams.length} teams)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Tap to expand/collapse teams',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            children: countryTeams.map((team) {
                              return ListTile(
                                leading: team.logoUrl != null
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(team.logoUrl!),
                                        onBackgroundImageError: (_, __) {},
                                      )
                                    : CircleAvatar(
                                        backgroundColor: Colors.grey[700],
                                        child: Icon(
                                          _getSportIcon(team.sport),
                                          color: Colors.white,
                                        ),
                                      ),
                                title: Text(
                                  team.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sport: ${team.sport}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    if (team.logoUrl != null)
                                      Text(
                                        'Has Logo: ✅',
                                        style: TextStyle(color: Colors.green[300], fontSize: 10),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.lime),
                                      onPressed: () => _showEditTeamDialog(team),
                                      tooltip: 'Edit Team',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteTeam(team.id),
                                      tooltip: 'Delete Team',
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
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

  Stream<List<Team>> _getFilteredTeamsStream() {
    if (_selectedChampionId != null) {
      return _service.getTeamsByChampion(_selectedChampionId!);
    } else if (_selectedCountryId != null) {
      return _service.getTeamsByCountryAndSport(_selectedCountryId!, _selectedSport);
    } else {
      return _service.getTeamsBySport(_selectedSport);
    }
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

  String _getNavigationSummary() {
    if (_selectedChampionId != null) {
      return 'Teams in $_selectedSport league: $_selectedChampionId';
    } else if (_selectedCountryId != null) {
      return 'Teams in $_selectedSport in $_selectedCountryId';
    } else {
      return 'All teams in $_selectedSport';
    }
  }

  void _showNavigationHelp() {
    // Implementation of _showNavigationHelp method
  }
}