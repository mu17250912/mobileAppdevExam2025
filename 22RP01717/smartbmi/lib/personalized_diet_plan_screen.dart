import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalizedDietPlanScreen extends StatefulWidget {
  const PersonalizedDietPlanScreen({super.key});

  @override
  State<PersonalizedDietPlanScreen> createState() => _PersonalizedDietPlanScreenState();
}

class _PersonalizedDietPlanScreenState extends State<PersonalizedDietPlanScreen> {
  int selectedDay = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Example user profile
  final Map<String, dynamic> userProfile = {
    'age': 28,
    'gender': 'Female',
    'weight': 65,
    'height': 170,
    'goal': 'Lose',
  };

  // Example meal plan for a day
  final List<Map<String, dynamic>> meals = [
    {
      'type': 'Breakfast',
      'name': 'Oatmeal with Berries',
      'calories': 320,
      'protein': 8,
      'carbs': 60,
      'fat': 6,
      'ingredients': ['Oats', 'Berries', 'Milk'],
    },
    {
      'type': 'Lunch',
      'name': 'Grilled Chicken Salad',
      'calories': 400,
      'protein': 30,
      'carbs': 20,
      'fat': 15,
      'ingredients': ['Chicken', 'Lettuce', 'Tomato', 'Olive Oil'],
    },
    {
      'type': 'Dinner',
      'name': 'Salmon & Veggies',
      'calories': 500,
      'protein': 35,
      'carbs': 25,
      'fat': 20,
      'ingredients': ['Salmon', 'Broccoli', 'Carrots'],
    },
    {
      'type': 'Snack',
      'name': 'Greek Yogurt',
      'calories': 120,
      'protein': 10,
      'carbs': 8,
      'fat': 3,
      'ingredients': ['Greek Yogurt'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personalized Diet Plan', style: GoogleFonts.montserrat()),
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
              _UserProfileCard(userProfile: userProfile),
              const SizedBox(height: 16),
              _DaySelector(
                days: days,
                selected: selectedDay,
                onChanged: (i) => setState(() => selectedDay = i),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: meals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _MealCard(meal: meals[i]),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Shopping List'),
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
          const Icon(Icons.person, color: Color(0xFF5676EA), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age: ${userProfile['age']}, ${userProfile['gender']}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                Text('Weight: ${userProfile['weight']} kg, Height: ${userProfile['height']} cm', style: GoogleFonts.montserrat()),
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

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  const _MealCard({required this.meal});

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
              Text(meal['type'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {},
                child: const Text('Swap'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5676EA)),
              ),
            ],
          ),
          Text(meal['name'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              _MacroChip(label: 'Kcal', value: meal['calories'].toString()),
              const SizedBox(width: 8),
              _MacroChip(label: 'P', value: '${meal['protein']}g'),
              const SizedBox(width: 8),
              _MacroChip(label: 'C', value: '${meal['carbs']}g'),
              const SizedBox(width: 8),
              _MacroChip(label: 'F', value: '${meal['fat']}g'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ingredients: ${meal['ingredients'].join(', ')}', style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  const _MacroChip({required this.label, required this.value});

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