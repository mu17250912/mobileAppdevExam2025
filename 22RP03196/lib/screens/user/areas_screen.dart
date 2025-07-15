import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'workouts_screen.dart';

class AreasScreen extends StatelessWidget {
  const AreasScreen({super.key});

  void _onAdvancedTap(BuildContext context, AppUser? user) {
    if (user?.isPremium == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Advanced Area'),
          content: Text('Welcome to the advanced area!'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
        ),
      );
    } else {
      Navigator.pushNamed(context, '/go_premium');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>
    (
      stream: AuthService().user,
      builder: (context, snap) {
        final user = snap.data;
        void goToArea(String area) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutsScreen(area: area),
            ),
          );
        }
        final areas = [
          {'label': 'Full-Body', 'icon': Icons.accessibility_new, 'onTap': () => goToArea('Full-Body')},
          {'label': 'Advanced', 'icon': Icons.fitness_center, 'onTap': () => _onAdvancedTap(context, user)},
          {'label': 'Pride', 'icon': Icons.emoji_events, 'onTap': () => goToArea('Pride')},
          {'label': 'Cardio', 'icon': Icons.directions_run, 'onTap': () => goToArea('Cardio')},
          {'label': 'Yoga', 'icon': Icons.self_improvement, 'onTap': () => goToArea('Yoga')},
          {'label': 'HIIT', 'icon': Icons.flash_on, 'onTap': () => goToArea('HIIT')},
          {'label': 'Strength', 'icon': Icons.sports_mma, 'onTap': () => goToArea('Strength')},
          {'label': 'Flexibility', 'icon': Icons.accessibility, 'onTap': () => goToArea('Flexibility')},
        ];
        return Scaffold(
          backgroundColor: const Color(0xFF22A6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF22A6F2),
            elevation: 0,
            title: Text('Apps', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: areas.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: a['onTap'] as VoidCallback,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      child: Row(
                        children: [
                          Icon(a['icon'] as IconData, size: 32, color: const Color(0xFF22A6F2)),
                          SizedBox(width: 18),
                          Text(a['label'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF22A6F2))),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        );
      },
    );
  }
} 