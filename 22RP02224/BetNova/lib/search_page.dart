import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<_SearchResult> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';
  Future<void>? _searchFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text.trim();
    if (query == _lastQuery) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _lastQuery = query;
    });
    if (_searchFuture != null) return;
    _searchFuture = _performSearch(query).whenComplete(() {
      _searchFuture = null;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    try {
      final List<_SearchResult> results = [];
      // Matches
      final matchesSnap = await FirebaseFirestore.instance
          .collection('matches')
          .where('keywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();
      for (var doc in matchesSnap.docs) {
        results.add(_SearchResult(
          type: 'Match',
          title: '${doc['teamA']} vs ${doc['teamB']}',
          subtitle: DateFormat('h:mm a EEE dd/MM').format(doc['dateTimeStart'].toDate()),
          icon: Icons.sports_soccer,
        ));
      }
      // Teams
      final teamsSnap = await FirebaseFirestore.instance
          .collection('teams')
          .where('keywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();
      for (var doc in teamsSnap.docs) {
        results.add(_SearchResult(
          type: 'Team',
          title: doc['name'],
          subtitle: doc['sport'],
          icon: Icons.groups,
        ));
      }
      // Leagues/Champions
      final leaguesSnap = await FirebaseFirestore.instance
          .collection('champions')
          .where('keywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();
      for (var doc in leaguesSnap.docs) {
        results.add(_SearchResult(
          type: 'League',
          title: doc['name'],
          subtitle: doc['sport'],
          icon: Icons.emoji_events,
        ));
      }
      // Users
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('keywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();
      for (var doc in usersSnap.docs) {
        results.add(_SearchResult(
          type: 'User',
          title: doc['displayName'] ?? doc['email'],
          subtitle: doc['email'],
          icon: Icons.person,
        ));
      }
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.lime,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.lime, fontSize: 18, fontWeight: FontWeight.bold),
          cursorColor: Colors.lime,
          decoration: InputDecoration(
            hintText: 'Search matches, teams, leagues, users...',
            hintStyle: TextStyle(color: Colors.lime[200]),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.lime),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged();
                    },
                  )
                : null,
          ),
          onChanged: (v) => _onSearchChanged(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.lime))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _results.isEmpty && _controller.text.isNotEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: Colors.lime, size: 60),
                          SizedBox(height: 16),
                          Text('No results found', style: TextStyle(color: Colors.lime, fontSize: 18)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.lime, height: 24),
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        return Card(
                          color: Colors.grey[850],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Icon(r.icon, color: Colors.lime, size: 32),
                            title: _highlight(r.title, _controller.text),
                            subtitle: _highlight(r.subtitle, _controller.text, color: Colors.lime[200]),
                            trailing: Text(r.type, style: const TextStyle(color: Colors.lime, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _highlight(String text, String query, {Color? color}) {
    if (query.isEmpty) return Text(text, style: TextStyle(color: color ?? Colors.lime, fontWeight: FontWeight.bold));
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    if (!lower.contains(q)) {
      return Text(text, style: TextStyle(color: color ?? Colors.lime));
    }
    final start = lower.indexOf(q);
    final end = start + q.length;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, start), style: TextStyle(color: color ?? Colors.lime)),
          TextSpan(text: text.substring(start, end), style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(end), style: TextStyle(color: color ?? Colors.lime)),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  _SearchResult({required this.type, required this.title, required this.subtitle, required this.icon});
} 