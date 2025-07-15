import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'models.dart';
import 'admin_edit_match_screen.dart';

class AdminMatchManagement extends StatefulWidget {
  const AdminMatchManagement({super.key});

  @override
  State<AdminMatchManagement> createState() => _AdminMatchManagementState();
}

class _AdminMatchManagementState extends State<AdminMatchManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedSport;
  String? _selectedCountryId;
  String? _selectedChampionId;
  String? _selectedHomeTeamId;
  String? _selectedAwayTeamId;
  String? _selectedTrend = 'Normal';

  double? _homeOdds;
  double? _drawOdds;
  double? _awayOdds;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  bool _isVisible = true;

  final List<String> _sports = ['Football', 'Basketball', 'Volleyball'];
  final List<String> _trends = ['Normal', 'Trending', 'Hot', 'Featured'];

  final List<Country> _lastCountryList = [];
  final List<Champion> _lastChampionList = [];
  final List<Team> _lastTeamList = [];

  final List<Map<String, dynamic>> _markets = [];

  final Map<String, List<String>> _marketOptions = {
    '1X2': ['Home', 'Draw', 'Away'],
    'Over/Under 2.5': ['Over', 'Under'],
    'BTTS': ['Yes', 'No'],
    'Handicap': ['Home', 'Away'],
    'Double Chance': ['1X', '2X', '12'], // 1X: Home or Draw, 2X: Away or Draw, 12: Home or Away (no draw)
    'Correct Score': ['Score'],
    'Total Goals': ['Over', 'Under'],
    'Both Teams to Score': ['Yes', 'No'],
    'Draw No Bet': ['Home', 'Away'],
    'First Half Result': ['Home', 'Draw', 'Away'],
    'Second Half Result': ['Home', 'Draw', 'Away'],
    'Odd/Even': ['Odd', 'Even'],
    'First Team to Score': ['Home', 'Away', 'No Goal'],
    'Last Team to Score': ['Home', 'Away', 'No Goal'],
    'Clean Sheet': ['Home', 'Away', 'None'],
    // Add more as needed
  };
  final List<String> _marketTypes = [
    '1X2',
    'Double Chance',
    'Over/Under 2.5',
    'BTTS',
    'Handicap',
    'Correct Score',
    'Total Goals',
    'Both Teams to Score',
    'Draw No Bet',
    'First Half Result',
    'Second Half Result',
    'Odd/Even',
    'First Team to Score',
    'Last Team to Score',
    'Clean Sheet',
    // Add more as needed
  ];

  void _addMarket() {
    setState(() {
      _markets.add({'type': null, 'odds': {}});
    });
  }

  void _removeMarket(int index) {
    setState(() {
      _markets.removeAt(index);
    });
  }

  Future<List<Champion>> _loadLeagues(String countryId, String sport) async {
    try {
      final champions = await _firestoreService.getChampionsByCountryAndSport(countryId, sport).first;
      if (champions.isNotEmpty) return champions;
      // fallback: try robust method
      final country = _lastCountryList.firstWhere((c) => c.id == countryId, orElse: () => Country(id: countryId, name: '', code: ''));
      final robust = await _firestoreService.getChampionsByCountryRobust(countryId, country.name);
      return robust;
    } catch (e, st) {
      print('Error loading leagues: $e\n$st');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedSport = null;
      _selectedCountryId = null;
      _selectedChampionId = null;
      _selectedHomeTeamId = null;
      _selectedAwayTeamId = null;
      _selectedTrend = 'Normal';
      _homeOdds = null;
      _drawOdds = null;
      _awayOdds = null;
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 20, minute: 0);
      _isVisible = true;
      _markets.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final country = _lastCountryList.firstWhere((c) => c.id == _selectedCountryId, orElse: () => Country(id: _selectedCountryId ?? '', name: '', code: ''));
      final champion = _lastChampionList.firstWhere(
        (ch) => ch.id == _selectedChampionId,
        orElse: () => Champion(id: _selectedChampionId ?? '', name: '', countryId: '', countryName: '', sport: ''),
      );
      final homeTeam = _lastTeamList.firstWhere((t) => t.id == _selectedHomeTeamId, orElse: () => Team(id: _selectedHomeTeamId ?? '', name: '', countryId: '', sport: ''));
      final awayTeam = _lastTeamList.firstWhere((t) => t.id == _selectedAwayTeamId, orElse: () => Team(id: _selectedAwayTeamId ?? '', name: '', countryId: '', sport: ''));
      final matchDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final odds = <String, Map<String, dynamic>>{};
      for (final market in _markets) {
        if (market['type'] != null && market['odds'] != null) {
          odds[market['type']] = Map<String, dynamic>.from(market['odds']);
        }
      }
      final match = Match(
        id: '',
        sport: _selectedSport ?? '',
        countryId: country.id,
        teamA: homeTeam.name,
        teamB: awayTeam.name,
        dateTimeStart: matchDateTime,
        dateTimeEnd: matchDateTime.add(const Duration(hours: 2)),
        odds: odds,
        category: champion.name,
        visible: _isVisible,
        result: null,
        status: 'open',
        marketingLabel: _selectedTrend,
        championId: champion.id,
      );
      await _firestoreService.addMatch(match);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match saved successfully!'), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save match: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Admin Match Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 1,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Match List'),
              Tab(text: 'Add/Edit Match'),
            ],
            indicatorColor: Colors.lime,
          ),
        ),
        body: TabBarView(
          children: [
            // --- Match List ---
            _buildMatchList(),
            // --- Add/Edit Match ---
            SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Match Info ---
                        const Text('Match Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: DropdownButtonFormField<String>(
                              value: _selectedSport,
                              decoration: const InputDecoration(labelText: 'Sport'),
                              items: _sports.map((sport) => DropdownMenuItem(value: sport, child: Text(sport))).toList(),
                              onChanged: (val) => setState(() { _selectedSport = val; }),
                              validator: (val) => val == null ? 'Select sport' : null,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: FutureBuilder<List<Country>>(
                              future: _firestoreService.getCountries().first,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                if (snapshot.hasError) return const Text('Failed to load countries');
                                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No countries found');
                                final countries = snapshot.data!;
                                _lastCountryList.clear(); _lastCountryList.addAll(countries);
                                return DropdownButtonFormField<String>(
                                  value: _selectedCountryId,
                                  decoration: const InputDecoration(labelText: 'Country'),
                                  items: countries.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.code})'))).toList(),
                                  onChanged: (val) => setState(() { _selectedCountryId = val; _selectedChampionId = null; _selectedHomeTeamId = null; _selectedAwayTeamId = null; }),
                                  validator: (val) => val == null ? 'Select country' : null,
                                );
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedCountryId != null && _selectedSport != null)
                          FutureBuilder<List<Champion>>(
                            future: _loadLeagues(_selectedCountryId!, _selectedSport!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                              if (snapshot.hasError) return Text('Failed to load leagues: \n${snapshot.error}');
                              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No leagues found');
                              final champions = snapshot.data!;
                              _lastChampionList.clear(); _lastChampionList.addAll(champions);
                              return DropdownButtonFormField<String>(
                                value: _selectedChampionId,
                                decoration: const InputDecoration(labelText: 'League/Champion'),
                                items: champions.map((ch) => DropdownMenuItem(value: ch.id, child: Text(ch.name))).toList(),
                                onChanged: (val) => setState(() { _selectedChampionId = val; _selectedHomeTeamId = null; _selectedAwayTeamId = null; }),
                                validator: (val) => val == null ? 'Select league/champion' : null,
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Date'),
                                child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                              ),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Time'),
                                child: Text(_selectedTime.format(context)),
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedTrend,
                          decoration: const InputDecoration(labelText: 'Trend/Label'),
                          items: _trends.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setState(() => _selectedTrend = val),
                        ),
                        const Divider(height: 32),

                        // --- Teams ---
                        const Text('Teams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 12),
                        if (_selectedChampionId != null)
                          Row(
                            children: [
                              Expanded(child: FutureBuilder<List<Team>>(
                                future: _firestoreService.getTeamsByChampionFuture(_selectedChampionId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                  if (snapshot.hasError) return const Text('Failed to load teams');
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No teams found');
                                  final teams = snapshot.data!;
                                  _lastTeamList.clear(); _lastTeamList.addAll(teams);
                                  return DropdownButtonFormField<String>(
                                    value: _selectedHomeTeamId,
                                    decoration: const InputDecoration(labelText: 'Home Team'),
                                    items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                                    onChanged: (val) => setState(() { _selectedHomeTeamId = val; }),
                                    validator: (val) => val == null ? 'Select home team' : null,
                                  );
                                },
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: FutureBuilder<List<Team>>(
                                future: _firestoreService.getTeamsByChampionFuture(_selectedChampionId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                  if (snapshot.hasError) return const Text('Failed to load teams');
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No teams found');
                                  final teams = snapshot.data!;
                                  return DropdownButtonFormField<String>(
                                    value: _selectedAwayTeamId,
                                    decoration: const InputDecoration(labelText: 'Away Team'),
                                    items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                                    onChanged: (val) => setState(() { _selectedAwayTeamId = val; }),
                                    validator: (val) => val == null ? 'Select away team' : null,
                                  );
                                },
                              )),
                            ],
                          ),
                        const Divider(height: 32),

                        // --- Odds/Markets ---
                        const Text('Markets & Odds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 12),
                        ..._markets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final market = entry.value;
                          final type = market['type'] as String?;
                          final odds = Map<String, dynamic>.from(market['odds'] ?? {});
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: type,
                                          decoration: const InputDecoration(labelText: 'Market Type'),
                                          items: _marketTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _markets[idx]['type'] = val;
                                              _markets[idx]['odds'] = {};
                                            });
                                          },
                                          validator: (val) => val == null ? 'Select market' : null,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeMarket(idx),
                                        tooltip: 'Remove Market',
                                      ),
                                    ],
                                  ),
                                  if (type != null && _marketOptions[type] != null)
                                    ..._marketOptions[type]!.map((option) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextFormField(
                                        initialValue: odds[option]?.toString() ?? '',
                                        decoration: InputDecoration(labelText: '$option Odds'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            _markets[idx]['odds'][option] = double.tryParse(v);
                                          });
                                        },
                                        validator: (v) => v == null || v.isEmpty ? 'Enter odds' : null,
                                      ),
                                    )),
                                ],
                              ),
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, color: Colors.deepPurple),
                            label: const Text('Add Market', style: TextStyle(color: Colors.deepPurple)),
                            onPressed: _addMarket,
                          ),
                        ),
                        const Divider(height: 32),

                        // --- Visibility & Save ---
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('Visible'),
                                value: _isVisible,
                                onChanged: (v) => setState(() => _isVisible = v),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Save Match'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(140, 48),
                                ),
                                onPressed: _saveMatch,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList() {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.getMatches().map((matches) => matches..sort((a, b) => b.dateTimeStart.compareTo(a.dateTimeStart))),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('Failed to load matches'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No matches found.'));
        final matches = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final match = matches[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${match.teamA} vs ${match.teamB}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminEditMatchScreen(match: match),
                                  ),
                                );
                              },
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(match.visible ? Icons.visibility : Icons.visibility_off, color: Colors.purple),
                              onPressed: () async {
                                await _firestoreService.updateMatch(match.id, {'visible': !match.visible});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Visibility updated!')),
                                );
                              },
                              tooltip: match.visible ? 'Hide Match' : 'Show Match',
                            ),
                            IconButton(
                              icon: Icon(match.status == 'open' ? Icons.lock_open : Icons.lock, color: Colors.orange),
                              onPressed: () async {
                                await _firestoreService.updateMatch(match.id, {
                                  'status': match.status == 'open' ? 'closed' : 'open',
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Match status updated!')),
                                );
                              },
                              tooltip: match.status == 'open' ? 'Close Match' : 'Open Match',
                            ),
                            IconButton(
                              icon: const Icon(Icons.sports_score, color: Colors.green),
                              onPressed: () async {
                                final TextEditingController resultController = TextEditingController(text: match.result ?? '');
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Set Match Result'),
                                    content: TextField(
                                      controller: resultController,
                                      decoration: const InputDecoration(labelText: 'Final Score (e.g. 2-1)'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, resultController.text.trim()),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result != null && result.isNotEmpty) {
                                  await _firestoreService.updateMatch(match.id, {'result': result});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Result updated!')),
                                  );
                                }
                              },
                              tooltip: 'Set Result',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _firestoreService.deleteMatch(match.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Match deleted!')),
                                );
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${match.category} | ${match.sport}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Match List', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: StreamBuilder<List<Match>>(
                  stream: firestoreService.getUpcomingMatches(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final matches = snapshot.data!;
                    if (matches.isEmpty) return const Center(child: Text('No matches found.'));
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(
                              '${match.teamA} vs ${match.teamB}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              '${match.category} | ${match.sport}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminEditMatchScreen(match: match),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await firestoreService.deleteMatch(match.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Match deleted!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(match.status == 'open' ? Icons.lock_open : Icons.lock, color: Colors.orange),
                                  onPressed: () async {
                                    await firestoreService.updateMatch(match.id, {
                                      'status': match.status == 'open' ? 'closed' : 'open',
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Match status updated!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget getCountryFlag(String countryCode) {
  // Map country codes to flag emojis
  final flagMap = {
    'RW': '🇷🇼', 'KE': '🇰🇪', 'UG': '🇺🇬', 'TZ': '🇹🇿', 'NG': '🇳🇬',
    'GH': '🇬🇭', 'ZA': '🇿🇦', 'EG': '🇪🇬', 'MA': '🇲🇦', 'TN': '🇹🇳',
    'DZ': '🇩🇿', 'LY': '🇱🇾', 'SD': '🇸🇩', 'ET': '🇪🇹', 'SO': '🇸🇴',
    'DJ': '🇩🇯', 'ER': '🇪🇷', 'SS': '🇸🇸', 'CF': '🇨🇫', 'TD': '🇹🇩',
    'CM': '🇨🇲', 'GQ': '🇬🇶', 'GA': '🇬🇦', 'CG': '🇨🇬', 'CD': '🇨🇩',
    'AO': '🇦🇴', 'ZM': '🇿🇲', 'ZW': '🇿🇼', 'BW': '🇧🇼', 'NA': '🇳🇦',
    'SZ': '🇸🇿', 'LS': '🇱🇸', 'MW': '🇲🇼', 'MZ': '🇲🇿', 'ZW': '🇿🇼',
    'MG': '🇲🇬', 'MU': '🇲🇺', 'SC': '🇸🇨', 'KM': '🇰🇲', 'KM': '🇰🇲',
    'BI': '🇧🇮', 'RW': '🇷🇼', 'TZ': '🇹🇿', 'UG': '🇺🇬', 'KE': '🇰🇪',
  };
  
  return Text(
    flagMap[countryCode] ?? '🏳️',
    style: const TextStyle(fontSize: 20),
  );
}

