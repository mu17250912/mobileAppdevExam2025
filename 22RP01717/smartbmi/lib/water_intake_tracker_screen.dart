import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterIntakeTrackerScreen extends StatefulWidget {
  const WaterIntakeTrackerScreen({super.key});

  @override
  State<WaterIntakeTrackerScreen> createState() => _WaterIntakeTrackerScreenState();
}

class _WaterIntakeTrackerScreenState extends State<WaterIntakeTrackerScreen> {
  final Map<String, dynamic> userProfile = {
    'age': 28,
    'gender': 'Female',
    'goal': 'Stay Hydrated',
  };
  double dailyGoal = 2.5; // liters
  double consumed = 0.0; // liters
  bool remindersOn = true;
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;
  bool noUser = false;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
    _loadReminder();
  }

  void _loadWaterData() {
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
    FirestoreService.waterEntriesStream(user.uid).listen((data) {
      setState(() {
        history = data;
        consumed = data.isNotEmpty && data.first['date'] == DateTime.now().toIso8601String().substring(0, 10)
          ? (data.first['amount'] as num).toDouble() : 0.0;
        isLoading = false;
      });
    });
  }

  void _loadReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final reminder = await FirestoreService.getWaterReminder(user.uid);
    if (reminder != null && mounted) {
      setState(() {
        remindersOn = reminder['enabled'] ?? true;
      });
    }
  }

  Future<void> _addWater(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await FirestoreService.addWaterEntry(user.uid, {'date': today, 'amount': amount});
  }

  Future<void> _toggleReminder(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => remindersOn = value);
    await FirestoreService.setWaterReminder(user.uid, value, '08:00'); // Default time
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water Intake Tracker', style: GoogleFonts.montserrat()),
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
                  const Center(child: Text('You must be logged in to view your water intake.')),
                if (!noUser) ...[
                  _UserProfileCard(userProfile: userProfile),
                  const SizedBox(height: 16),
                  _WaterGoalProgress(dailyGoal: dailyGoal, consumed: consumed),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: _WaterBarChart(history: history),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addWater(consumed + 0.25),
                          icon: const Icon(Icons.local_drink),
                          label: const Text('Add 250ml'),
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
                          icon: const Icon(Icons.add),
                          label: const Text('Custom Amount'),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: remindersOn,
                        onChanged: _toggleReminder,
                        activeColor: const Color(0xFF5676EA),
                      ),
                      const SizedBox(width: 8),
                      Text('Daily Reminders', style: GoogleFonts.montserrat()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('History', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!isLoading)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _HistoryCard(entry: history[i]),
                    ),
                  const SizedBox(height: 18),
                  Text('Resources', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  _ResourceCard(
                    title: 'How Much Water Should You Drink?',
                    url: 'https://www.cdc.gov/healthyweight/healthy_eating/water-and-healthier-drinks.html',
                  ),
                  _ResourceCard(
                    title: 'Hydration Tips',
                    url: 'https://www.healthline.com/nutrition/how-much-water-should-you-drink-per-day',
                  ),
                  _ResourceCard(
                    title: 'YouTube: Hydration Explained',
                    url: 'https://www.youtube.com/watch?v=9iMGFqMmUFs',
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
          const Icon(Icons.water_drop, color: Color(0xFF5676EA), size: 32),
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

class _WaterGoalProgress extends StatelessWidget {
  final double dailyGoal;
  final double consumed;
  const _WaterGoalProgress({required this.dailyGoal, required this.consumed});

  @override
  Widget build(BuildContext context) {
    double percent = (consumed / dailyGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today: ${consumed.toStringAsFixed(1)} / ${dailyGoal.toStringAsFixed(1)} L', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          minHeight: 12,
          backgroundColor: Colors.grey[200],
          color: const Color(0xFF5676EA),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFF5676EA)),
        title: Text('Date: ${entry['date']}', style: GoogleFonts.montserrat()),
        subtitle: Text('Amount: ${entry['amount']} L', style: GoogleFonts.montserrat(fontSize: 13)),
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

class _WaterBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _WaterBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(child: Text('No data', style: GoogleFonts.montserrat(color: Colors.black54)));
    }
    final bars = history.reversed.take(7).toList().reversed.mapIndexed((i, e) => BarChartRodData(toY: (e['amount'] as num).toDouble(), color: const Color(0xFF5676EA))).toList();
    return BarChart(
      BarChartData(
        barGroups: List.generate(bars.length, (i) => BarChartGroupData(x: i, barRods: [bars[i]])),
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