import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'firestore_service.dart';
import 'admin_match_management.dart';

class AdminEditMatchScreen extends StatefulWidget {
  final Match? match;

  const AdminEditMatchScreen({super.key, this.match});

  @override
  State<AdminEditMatchScreen> createState() => _AdminEditMatchScreenState();
}

class _AdminEditMatchScreenState extends State<AdminEditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Form Controllers for odds
  final _oddsTeamAController = TextEditingController();
  final _oddsDrawController = TextEditingController();
  final _oddsTeamBController = TextEditingController();
  final _oddsOver25Controller = TextEditingController();
  final _oddsUnder25Controller = TextEditingController();
  final _oddsBttsYesController = TextEditingController();
  final _oddsBttsNoController = TextEditingController();
  
  final _categoryController = TextEditingController();
  final _marketingLabelController = TextEditingController();

  // Form State
  String? _selectedSport;
  String? _selectedCountryId;
  String? _selectedChampionId;
  String? _selectedTeamAName;
  String? _selectedTeamBName;
  DateTime? _dateTimeStart;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      final match = widget.match!;
      _selectedSport = match.sport;
      _selectedCountryId = match.countryId;
      _selectedChampionId = match.championId;
      _selectedTeamAName = match.teamA;
      _selectedTeamBName = match.teamB;
      _dateTimeStart = match.dateTimeStart;
      
      // Populate odds controllers from the flexible map
      _oddsTeamAController.text = match.odds['match_winner']?['teamA']?.toString() ?? '';
      _oddsDrawController.text = match.odds['match_winner']?['draw']?.toString() ?? '';
      _oddsTeamBController.text = match.odds['match_winner']?['teamB']?.toString() ?? '';
      _oddsOver25Controller.text = match.odds['over_under_2_5']?['over']?.toString() ?? '';
      _oddsUnder25Controller.text = match.odds['over_under_2_5']?['under']?.toString() ?? '';
      _oddsBttsYesController.text = match.odds['btts']?['yes']?.toString() ?? '';
      _oddsBttsNoController.text = match.odds['btts']?['no']?.toString() ?? '';

      _categoryController.text = match.category;
      _marketingLabelController.text = match.marketingLabel ?? '';
      _visible = match.visible;
    }
  }

  @override
  void dispose() {
    _oddsTeamAController.dispose();
    _oddsDrawController.dispose();
    _oddsTeamBController.dispose();
    _oddsOver25Controller.dispose();
    _oddsUnder25Controller.dispose();
    _oddsBttsYesController.dispose();
    _oddsBttsNoController.dispose();
    _categoryController.dispose();
    _marketingLabelController.dispose();
    super.dispose();
  }
  
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTimeStart ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTimeStart ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _dateTimeStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveMatch() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedTeamAName == _selectedTeamBName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team A and Team B must be different!'), backgroundColor: Colors.red),
        );
        return;
      }

      final Map<String, dynamic> odds = {
        'match_winner': {
          'teamA': double.tryParse(_oddsTeamAController.text) ?? 0,
          'draw': double.tryParse(_oddsDrawController.text) ?? 0,
          'teamB': double.tryParse(_oddsTeamBController.text) ?? 0,
        },
        'over_under_2_5': {
          'over': double.tryParse(_oddsOver25Controller.text) ?? 0,
          'under': double.tryParse(_oddsUnder25Controller.text) ?? 0,
        },
        'btts': {
          'yes': double.tryParse(_oddsBttsYesController.text) ?? 0,
          'no': double.tryParse(_oddsBttsNoController.text) ?? 0,
        },
      };

      final matchData = {
        'sport': _selectedSport,
        'countryId': _selectedCountryId,
        'championId': _selectedChampionId,
        'teamA': _selectedTeamAName,
        'teamB': _selectedTeamBName,
        'dateTimeStart': _dateTimeStart,
        'dateTimeEnd': _dateTimeStart?.add(const Duration(hours: 2)),
        'odds': odds,
        'category': _categoryController.text,
        'visible': _visible,
        'status': 'open',
        'marketingLabel': _marketingLabelController.text.isEmpty ? null : _marketingLabelController.text,
      };

      if (widget.match == null) {
        await _firestoreService.addMatch(
          Match(
            id: '',
            sport: _selectedSport ?? '',
            countryId: _selectedCountryId ?? '',
            championId: _selectedChampionId ?? '',
            teamA: _selectedTeamAName ?? '',
            teamB: _selectedTeamBName ?? '',
            dateTimeStart: _dateTimeStart!,
            dateTimeEnd: _dateTimeStart!.add(const Duration(hours: 2)),
            odds: odds,
            category: _categoryController.text,
            visible: _visible,
            result: null,
            status: 'open',
            marketingLabel: _marketingLabelController.text.isEmpty ? null : _marketingLabelController.text,
          ),
        );
      } else {
        await _firestoreService.updateMatch(widget.match!.id, matchData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MatchListScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.match == null ? 'Add Match' : 'Edit Match',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Match Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                        // Sport Selection
                        DropdownButtonFormField<String>(
                          value: _selectedSport,
                          hint: const Text('Select Sport'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Football', child: Text('Football')),
                            DropdownMenuItem(value: 'Basketball', child: Text('Basketball')),
                            DropdownMenuItem(value: 'Volleyball', child: Text('Volleyball')),
                          ],
                          onChanged: (value) {
                            if (value != _selectedSport) {
                              setState(() {
                                _selectedSport = value;
                                _selectedCountryId = null;
                                _selectedChampionId = null;
                                _selectedTeamAName = null;
                                _selectedTeamBName = null;
                              });
                            }
                          },
                          validator: (value) => value == null ? 'Please select a sport' : null,
                        ),
                        const SizedBox(height: 16),
                        // Country Selection
                        if (_selectedSport != null)
                          StreamBuilder<List<Country>>(
                            stream: _firestoreService.getCountries(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              return DropdownButtonFormField<String>(
                                value: _selectedCountryId,
                                hint: const Text('Select Country'),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: snapshot.data!.map((country) {
                                  return DropdownMenuItem(
                                    value: country.id,
                                    child: Row(
                                      children: [
                                        getCountryFlag(country.code),
                                        const SizedBox(width: 8),
                                        Text(country.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != _selectedCountryId) {
                                    setState(() {
                                      _selectedCountryId = value;
                                      _selectedChampionId = null;
                                      _selectedTeamAName = null;
                                      _selectedTeamBName = null;
                                    });
                                  }
                                },
                                validator: (value) => value == null ? 'Please select a country' : null,
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        // Champion/League Selection
                        if (_selectedCountryId != null && _selectedSport != null)
                          FutureBuilder<Country?>(
                            future: _firestoreService.getCountry(_selectedCountryId!),
                            builder: (context, countrySnap) {
                              if (!countrySnap.hasData) return const Center(child: CircularProgressIndicator());
                              if (countrySnap.data == null) return const Text('Country not found.');
                              final countryName = countrySnap.data!.name;
                              return FutureBuilder<List<Champion>>(
                                future: _firestoreService.getChampionsByCountryNameAndSport(countryName, _selectedSport!).first,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('No champions found for this country and sport.'),
                                    );
                                  }
                                  final champions = snapshot.data!;
                                  final championValue = champions.any((c) => c.id == _selectedChampionId) ? _selectedChampionId : null;
                                  return DropdownButtonFormField<String>(
                                    value: championValue,
                                    items: champions.map((champion) {
                                      return DropdownMenuItem<String>(
                                        value: champion.id,
                                        child: Text(champion.name),
                                      );
                                    }).toList(),
                                    hint: const Text('Select Champion/League'),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      if (value != _selectedChampionId) {
                                        setState(() {
                                          _selectedChampionId = value;
                                          _selectedTeamAName = null;
                                          _selectedTeamBName = null;
                                        });
                                      }
                                    },
                                    validator: (value) => value == null ? 'Please select a champion/league' : null,
                                  );
                                }
                              );
                            }
                          ),
                        const SizedBox(height: 16),
                        // Teams
                        if (_selectedChampionId != null)
                          StreamBuilder<List<Team>>(
                            stream: _firestoreService.getTeamsByChampion(_selectedChampionId!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.red[50],
                                  ),
                                  child: const Text('No teams found for this champion/league.', style: TextStyle(color: Colors.red)),
                                );
                              }
                              final teams = snapshot.data!;
                              final teamAValue = teams.any((t) => t.name == _selectedTeamAName) ? _selectedTeamAName : null;
                              final teamBValue = teams.any((t) => t.name == _selectedTeamBName) ? _selectedTeamBName : null;
                              final teamItems = teams.map((team) {
                                return DropdownMenuItem<String>(
                                  value: team.name,
                                  child: Text(team.name),
                                );
                              }).toList();
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: teamAValue,
                                    items: teamItems,
                                    hint: const Text('Select Home Team'),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() => _selectedTeamAName = value);
                                    },
                                    validator: (value) => value == null ? 'Please select Home Team' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: teamBValue,
                                    items: teamItems,
                                    hint: const Text('Select Away Team'),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() => _selectedTeamBName = value);
                                    },
                                    validator: (value) {
                                      if (value == null) return 'Please select Away Team';
                                      if (value == teamAValue) return 'Away Team must be different from Home Team';
                                      return null;
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        // Date & Time
                        ListTile(
                          tileColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          title: const Text('Match Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_dateTimeStart == null
                              ? 'Not set'
                              : DateFormat.yMd().add_jm().format(_dateTimeStart!)),
                          trailing: const Icon(Icons.calendar_today, color: Colors.black54),
                          onTap: _pickDateTime,
                        ),
                        const Divider(),
                        // Odds
                        const Text('Match Winner Odds (1X2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _oddsTeamAController, decoration: const InputDecoration(labelText: 'Team A Win'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _oddsDrawController, decoration: const InputDecoration(labelText: 'Draw'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _oddsTeamBController, decoration: const InputDecoration(labelText: 'Team B Win'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Over/Under 2.5 Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _oddsOver25Controller, decoration: const InputDecoration(labelText: 'Over 2.5'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _oddsUnder25Controller, decoration: const InputDecoration(labelText: 'Under 2.5'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Both Teams to Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _oddsBttsYesController, decoration: const InputDecoration(labelText: 'Yes'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _oddsBttsNoController, decoration: const InputDecoration(labelText: 'No'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category (e.g., Premier League)')),
                        const SizedBox(height: 12),
                        TextFormField(controller: _marketingLabelController, decoration: const InputDecoration(labelText: 'Marketing Label (e.g., Trending)')),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Visible'),
                          value: _visible,
                          onChanged: (value) => setState(() => _visible = value),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveMatch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lime,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Save Match'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getCountryFlag(String countryCode) {
    // Map country codes to flag emojis
    final flagMap = {
      'RW': '🇷🇼', 'KE': '🇰🇪', 'UG': '🇺🇬', 'TZ': '🇹🇿', 'NG': '🇳🇬',
      'GH': '🇬🇭', 'ZA': '🇿🇦', 'EG': '🇪🇬', 'MA': '🇲🇦', 'TN': '🇹🇳',
      'DZ': '🇩🇿', 'LY': '🇱🇾', 'SD': '🇸🇩', 'ET': '🇪🇷', 'SO': '🇸🇴',
      'DJ': '🇩🇯', 'ER': '🇪🇷', 'SS': '🇸🇸', 'CF': '🇨🇫', 'TD': '🇹🇩',
      'CM': '🇨🇲', 'GQ': '🇬🇶', 'GA': '🇬🇦', 'CG': '🇨🇬', 'CD': '🇨🇩',
      'AO': '🇦🇴', 'ZM': '🇿🇲', 'ZW': '🇿🇼', 'BW': '🇧🇼', 'NA': '🇳🇦',
      // ignore: equal_keys_in_map
      'SZ': '🇸🇿', 'LS': '🇱🇸', 'MW': '🇲🇼', 'MZ': '🇲🇿', 'ZW': '🇿🇼',
      // ignore: equal_keys_in_map
      'MG': '🇲🇬', 'MU': '🇲🇺', 'SC': '🇸🇨', 'KM': '🇰🇲', 'KM': '🇰🇲',
      // ignore: equal_keys_in_map
      'BI': '🇧🇮', 'RW': '🇷🇼', 'TZ': '🇹🇿', 'UG': '🇺🇬', 'KE': '🇰🇪',
    };
    
    return Text(
      flagMap[countryCode] ?? '🏳️',
      style: const TextStyle(fontSize: 20),
    );
  }
}
