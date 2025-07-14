import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/achievement.dart';
import '../providers/task_provider.dart';
import '../services/hive_service.dart';
import '../theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _userAchievements = [];
  int _totalPoints = 0;
  int _unlockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final achievementBox = await HiveService().getAchievementsBox();
      
      if (achievementBox.isEmpty) {
        // Initialize with default achievements
        final defaultAchievements = AchievementService.getDefaultAchievements();
        await achievementBox.addAll(defaultAchievements);
      }

      setState(() {
        _userAchievements = achievementBox.values.toList();
        _totalPoints = _userAchievements.fold(0, (sum, achievement) => sum + (achievement.isUnlocked ? achievement.points : 0));
        _unlockedCount = _userAchievements.where((achievement) => achievement.isUnlocked).length;
      });
    } catch (e) {
      print('Error loading achievements: $e');
      // Set empty state if there's an error
      setState(() {
        _userAchievements = [];
        _totalPoints = 0;
        _unlockedCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements', style: AppTextStyles.heading),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview
            _buildStatsOverview(),
            const SizedBox(height: 24),

            // Recent Unlocks
            if (_unlockedCount > 0) ...[
              Text(
                'Recent Unlocks',
                style: AppTextStyles.subheading.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentUnlocks(),
              const SizedBox(height: 24),
            ],

            // All Achievements
            Text(
              'All Achievements',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievementsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple[600]!, Colors.purple[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Unlocked',
                  '$_unlockedCount',
                  Icons.emoji_events,
                ),
                _buildStatItem(
                  'Total Points',
                  '$_totalPoints',
                  Icons.stars,
                ),
                _buildStatItem(
                  'Progress',
                  '${((_unlockedCount / _userAchievements.length) * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _userAchievements.isNotEmpty ? _unlockedCount / _userAchievements.length : 0,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUnlocks() {
    final recentUnlocks = _userAchievements
        .where((achievement) => achievement.isUnlocked)
        .toList()
      ..sort((a, b) => (b.unlockedAt ?? DateTime.now()).compareTo(a.unlockedAt ?? DateTime.now()));

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentUnlocks.take(5).length,
        itemBuilder: (context, index) {
          final achievement = recentUnlocks[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '+${achievement.points} pts',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 8,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _userAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _userAchievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      elevation: achievement.isUnlocked ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: achievement.isUnlocked
              ? LinearGradient(
                  colors: [Colors.amber[600]!, Colors.amber[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: achievement.isUnlocked 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: achievement.isUnlocked ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Achievement Title
              Text(
                achievement.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: achievement.isUnlocked ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Achievement Description
              Text(
                achievement.description,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: achievement.isUnlocked 
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Progress Bar
              if (!achievement.isUnlocked) ...[
                LinearProgressIndicator(
                  value: achievement.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.currentValue}/${achievement.targetValue}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.points} pts',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 