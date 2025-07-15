import 'package:flutter/material.dart';
import '../services/sustainability_service.dart';

class StreakWidget extends StatelessWidget {
  final RetentionInsight insight;

  const StreakWidget({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    // Extract streak number from message
    final streakMatch = RegExp(r'(\d+)-day streak').firstMatch(insight.message);
    final streakNumber = streakMatch != null ? int.parse(streakMatch.group(1)!) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Streak number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '$streakNumber',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Streak label
          Text(
            'DAY STREAK!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Motivational message
          Text(
            _getMotivationalMessage(streakNumber),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Progress indicator
          _buildProgressIndicator(context, streakNumber),
          const SizedBox(height: 16),
          
          // Action button
          ElevatedButton(
            onPressed: () {
              // Navigate to adherence tracking
              Navigator.pushNamed(context, '/adherence');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'View Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(int streak) {
    if (streak >= 30) {
      return 'Incredible! You\'re a medication adherence champion! 🏆';
    } else if (streak >= 21) {
      return 'Amazing! You\'ve built a strong habit! 💪';
    } else if (streak >= 14) {
      return 'Fantastic! Two weeks of consistency! 🌟';
    } else if (streak >= 7) {
      return 'Great job! A full week of taking your medications! 🎉';
    } else if (streak >= 3) {
      return 'Excellent! You\'re building momentum! 🔥';
    } else {
      return 'Keep it up! Every day counts! 💯';
    }
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStreak) {
    // Define milestone targets
    const milestones = [7, 14, 21, 30, 60, 90];
    final nextMilestone = milestones.firstWhere(
      (milestone) => milestone > currentStreak,
      orElse: () => 100,
    );
    
    final progress = currentStreak / nextMilestone;
    final remainingDays = nextMilestone - currentStreak;

    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Progress text
        Text(
          '$currentStreak / $nextMilestone days',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        
        // Next milestone
        Text(
          remainingDays > 0 
              ? '$remainingDays days to next milestone!'
              : 'Milestone reached! 🎉',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 