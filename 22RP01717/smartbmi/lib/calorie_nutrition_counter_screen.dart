import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class CalorieNutritionCounterScreen extends StatefulWidget {
  const CalorieNutritionCounterScreen({super.key});

  @override
  State<CalorieNutritionCounterScreen> createState() => _CalorieNutritionCounterScreenState();
}

class _CalorieNutritionCounterScreenState extends State<CalorieNutritionCounterScreen> {
  final Map<String, dynamic> userProfile = {
    'age': 28,
    'gender': 'Female',
    'goal': 'Lose Weight',
  };
  int dailyGoal = 1800; // calories
  int consumed = 0; // calories
  List<Map<String, dynamic>> foods = [];
  bool isLoading = true;
  bool noUser = false;

  @override
  void initState() {
    super.initState();
    _loadCalorieData();
    _loadGoal();
  }

  void _loadCalorieData() {
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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    FirestoreService.foodEntriesStream(user.uid, today).listen((data) {
      setState(() {
        foods = data;
        consumed = data.fold(0, (sum, f) => sum + (f['calories'] as int));
        isLoading = false;
      });
    });
  }

  void _loadGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final goal = await FirestoreService.getCalorieGoal(user.uid);
    if (goal != null && mounted) {
      setState(() => dailyGoal = goal);
    }
  }

  Future<void> _addFood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    // For demo, add a random food
    final food = {
      'name': 'Apple',
      'calories': 95,
      'protein': 0,
      'carbs': 25,
      'fat': 0,
    };
    await FirestoreService.addFoodEntry(user.uid, today, food);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie & Nutrition Counter', style: GoogleFonts.montserrat()),
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
                  const Center(child: Text('You must be logged in to view your calorie & nutrition log.')),
                if (!noUser) ...[
                  _UserProfileCard(userProfile: userProfile),
                  const SizedBox(height: 16),
                  _CalorieGoalProgress(dailyGoal: dailyGoal, consumed: consumed),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: _CalorieBarChart(foods: foods),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addFood,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Food'),
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
                          label: const Text('Export Log'),
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
                  Text('Today\'s Foods', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!isLoading)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: foods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _FoodCard(food: foods[i]),
                    ),
                  const SizedBox(height: 18),
                  Text('Resources', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  _ResourceCard(
                    title: 'Calorie Counting 101',
                    url: 'https://www.medicalnewstoday.com/articles/what-to-know-about-calorie-counting',
                  ),
                  _ResourceCard(
                    title: 'Nutrition Basics',
                    url: 'https://www.choosemyplate.gov/',
                  ),
                  _ResourceCard(
                    title: 'YouTube: How to Track Calories',
                    url: 'https://www.youtube.com/watch?v=H3jJ29oE8Zg',
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
          const Icon(Icons.restaurant, color: Color(0xFF5676EA), size: 32),
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

class _CalorieGoalProgress extends StatelessWidget {
  final int dailyGoal;
  final int consumed;
  const _CalorieGoalProgress({required this.dailyGoal, required this.consumed});

  @override
  Widget build(BuildContext context) {
    double percent = (consumed / dailyGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today: $consumed / $dailyGoal kcal', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
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

class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fastfood, color: Color(0xFF5676EA)),
        title: Text(food['name'], style: GoogleFonts.montserrat()),
        subtitle: Text('Kcal: ${food['calories']}, P: ${food['protein']}g, C: ${food['carbs']}g, F: ${food['fat']}g', style: GoogleFonts.montserrat(fontSize: 13)),
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

class _CalorieBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> foods;
  const _CalorieBarChart({required this.foods});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Center(child: Text('No data', style: GoogleFonts.montserrat(color: Colors.black54)));
    }
    final bars = foods.take(7).toList().asMap().entries.map((e) => BarChartRodData(toY: (e.value['calories'] as num).toDouble(), color: const Color(0xFF5676EA))).toList();
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