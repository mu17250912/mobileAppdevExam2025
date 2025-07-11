import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  int selectedDay = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final Map<String, dynamic> userProfile = {
    'age': 28,
    'gender': 'Female',
    'goal': 'Build Muscle',
    'experience': 'Intermediate',
  };

  List<Map<String, dynamic>> workouts = [];
  bool isLoading = true;
  bool noUser = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
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
    final day = days[selectedDay];
    final data = await FirestoreService.getWorkoutPlan(user.uid, day);
    setState(() {
      workouts = data.isNotEmpty ? data : _defaultWorkouts();
      isLoading = false;
    });
  }

  Future<void> _saveWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final day = days[selectedDay];
    await FirestoreService.saveWorkoutPlan(user.uid, day, workouts);
  }

  List<Map<String, dynamic>> _defaultWorkouts() {
    return [
      {
        'type': 'Warm-up',
        'name': 'Jumping Jacks',
        'sets': 1,
        'reps': 30,
        'duration': '2 min',
        'equipment': 'None',
      },
      {
        'type': 'Strength',
        'name': 'Push-ups',
        'sets': 3,
        'reps': 12,
        'duration': '-',
        'equipment': 'None',
      },
      {
        'type': 'Strength',
        'name': 'Dumbbell Squats',
        'sets': 3,
        'reps': 15,
        'duration': '-',
        'equipment': 'Dumbbells',
      },
      {
        'type': 'Cardio',
        'name': 'Mountain Climbers',
        'sets': 2,
        'reps': 20,
        'duration': '1 min',
        'equipment': 'None',
      },
      {
        'type': 'Cool-down',
        'name': 'Stretching',
        'sets': 1,
        'reps': '-',
        'duration': '5 min',
        'equipment': 'None',
      },
    ];
  }

  void _onSwap(int i) async {
    setState(() {
      workouts[i]['name'] = workouts[i]['name'] == 'Push-ups' ? 'Plank' : 'Push-ups';
    });
    await _saveWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Plan Generator', style: GoogleFonts.montserrat()),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (noUser)
                const Center(child: Text('You must be logged in to view your workout plan.')),
              if (!noUser) ...[
                _UserProfileCard(userProfile: userProfile),
                const SizedBox(height: 16),
                _DaySelector(
                  days: days,
                  selected: selectedDay,
                  onChanged: (i) async {
                    setState(() => selectedDay = i);
                    await _loadWorkouts();
                  },
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (!isLoading)
                  Expanded(
                    child: ListView.separated(
                      itemCount: workouts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _WorkoutCard(
                        workout: workouts[i],
                        onSwap: () => _onSwap(i),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Add to Calendar'),
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
                        label: const Text('Export Plan'),
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
                  title: 'Beginner Workout Guide',
                  url: 'https://www.verywellfit.com/beginner-workout-routine-1230828',
                ),
                _ResourceCard(
                  title: 'YouTube: 20-Minute Full Body Workout',
                  url: 'https://www.youtube.com/watch?v=UBMk30rjy0o',
                ),
                _ResourceCard(
                  title: 'Proper Form Tips',
                  url: 'https://www.acefitness.org/education-and-resources/lifestyle/blog/6592/6-tips-for-proper-exercise-form/',
                ),
              ],
            ],
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
          const Icon(Icons.fitness_center, color: Color(0xFF5676EA), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age: ${userProfile['age']}, ${userProfile['gender']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                Text('Goal: ${userProfile['goal']}', style: GoogleFonts.montserrat()),
                Text('Experience: ${userProfile['experience']}', style: GoogleFonts.montserrat()),
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

class _DaySelector extends StatelessWidget {
  final List<String> days;
  final int selected;
  final ValueChanged<int> onChanged;
  const _DaySelector({required this.days, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (i) => GestureDetector(
        onTap: () => onChanged(i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: selected == i ? const Color(0xFF5676EA) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5676EA), width: 1),
          ),
          child: Text(
            days[i],
            style: GoogleFonts.montserrat(
              color: selected == i ? Colors.white : const Color(0xFF5676EA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  final VoidCallback? onSwap;
  const _WorkoutCard({required this.workout, this.onSwap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(workout['type'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: onSwap,
                child: const Text('Swap'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5676EA)),
              ),
            ],
          ),
          Text(workout['name'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              _WorkoutDetailChip(label: 'Sets', value: workout['sets'].toString()),
              const SizedBox(width: 8),
              _WorkoutDetailChip(label: 'Reps', value: workout['reps'].toString()),
              const SizedBox(width: 8),
              _WorkoutDetailChip(label: 'Duration', value: workout['duration']),
              const SizedBox(width: 8),
              _WorkoutDetailChip(label: 'Equipment', value: workout['equipment']),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutDetailChip extends StatelessWidget {
  final String label;
  final String value;
  const _WorkoutDetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5676EA).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF5676EA))),
          const SizedBox(width: 2),
          Text(value, style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF5676EA))),
        ],
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