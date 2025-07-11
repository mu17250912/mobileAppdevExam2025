import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  final Map<String, dynamic> userProfile = {
    'age': 28,
    'gender': 'Female',
    'goal': 'Lose Weight',
  };
  bool isLoading = true;
  List<Map<String, dynamic>> entries = [];
  bool noUser = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        noUser = true;
        isLoading = false;
      });
      return;
    }
    setState(() {
      isLoading = true;
      noUser = false;
    });
    FirestoreService.progressEntriesStream(user.uid).listen((data) {
      setState(() {
        entries = data;
        isLoading = false;
      });
    });
  }

  Future<void> _addEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final entry = {
      'date': now.toIso8601String().substring(0, 10),
      'weight': 65 + (entries.length % 3),
      'bmi': 23.0 + (entries.length % 3) * 0.2,
    };
    await FirestoreService.addProgressEntry(user.uid, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracker', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noUser)
                  const Center(child: Text('You must be logged in to view your progress.')),
                if (!noUser) ...[
                  _UserProfileCard(userProfile: userProfile),
                  const SizedBox(height: 16),
                  _ProgressSummary(summary: entries.isNotEmpty ? {
                    'weight': entries.first['weight'],
                    'bmi': entries.first['bmi'],
                    'calories': 1800,
                    'water': 2.2,
                  } : {'weight': '-', 'bmi': '-', 'calories': '-', 'water': '-'}),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: _ProgressChart(entries: entries),
                  ),
                  const SizedBox(height: 16),
                  Text('Recent Entries', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!isLoading)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EntryCard(entry: entries[i]),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addEntry,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5676EA),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                          label: const Text('Export Progress'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFF5676EA)),
                            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Resources', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  _ResourceCard(
                    title: 'How to Track Fitness Progress',
                    url: 'https://www.healthline.com/health/fitness-exercise/track-fitness-progress',
                  ),
                  _ResourceCard(
                    title: 'Best Progress Tracking Apps',
                    url: 'https://www.verywellfit.com/best-fitness-apps-4158220',
                  ),
                  _ResourceCard(
                    title: 'YouTube: Progress Tracking Tips',
                    url: 'https://www.youtube.com/watch?v=2pLT-olgUJs',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const _UserProfileCard({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.show_chart, color: Color(0xFF5676EA), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age: ${userProfile['age']}, ${userProfile['gender']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                Text('Goal: ${userProfile['goal']}', style: GoogleFonts.montserrat()),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Update Profile'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF5676EA)),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _ProgressSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SummaryChip(label: 'Weight', value: '${summary['weight']} kg'),
        _SummaryChip(label: 'BMI', value: summary['bmi'].toString()),
        _SummaryChip(label: 'Calories', value: '${summary['calories']}'),
        _SummaryChip(label: 'Water', value: '${summary['water']} L'),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5676EA).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF5676EA))),
          Text(value, style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF5676EA))),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Center(
        child: Text('BMI/Weight Chart (Coming Soon)', style: GoogleFonts.montserrat(color: Colors.black54)),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_note, color: Color(0xFF5676EA)),
        title: Text('Date: ${entry['date']}', style: GoogleFonts.montserrat()),
        subtitle: Text('Weight: ${entry['weight']} kg, BMI: ${entry['bmi']}', style: GoogleFonts.montserrat(fontSize: 13)),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String url;
  const _ResourceCard({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: GoogleFonts.montserrat()),
        trailing: const Icon(Icons.open_in_new, color: Color(0xFF5676EA)),
        onTap: () => _launchURL(context, url),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    // TODO: Implement url_launcher logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open: ' + url)),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _ProgressChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(child: Text('No data', style: GoogleFonts.montserrat(color: Colors.black54)));
    }
    final spots = entries.reversed.take(7).toList().reversed.mapIndexed((i, e) => FlSpot(i.toDouble(), (e['bmi'] as num).toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF5676EA),
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}

extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
} 