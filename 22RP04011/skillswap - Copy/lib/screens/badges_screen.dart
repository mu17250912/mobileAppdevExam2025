import 'package:flutter/material.dart';
import '../widgets/screen_wrapper.dart';
import '../models/chat_model.dart' as chat_model;
import '../services/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    // Check for new badges when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BadgeService.checkAllBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return ScreenWrapper(
      title: 'My Badges',
      showAppBar: true,
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 48 : 24,
                horizontal: isTablet ? 48 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events,
                      size: isTablet ? 120 : 80, color: Colors.amber),
                  SizedBox(height: isTablet ? 36 : 24),
                  Text(
                    'Your badges will appear here!',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 20 : 12),
                  Text(
                    'Earn badges by participating in SkillSwap activities.',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 40 : 24),
                  // Badge statistics
                  StreamBuilder<Map<String, dynamic>>(
                    stream:
                        Stream.fromFuture(BadgeService.getBadgeStatistics()),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final stats = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Progress: ${stats['progress']}%',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${stats['earnedBadges']} of ${stats['totalBadges']} badges earned',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: isTablet ? 32 : 24),
                  // Badge grid
                  StreamBuilder<List<chat_model.Badge>>(
                    stream: BadgeService.getUserBadges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final badges = snapshot.data ?? [];

                      if (badges.isEmpty) {
                        return GridView.count(
                          crossAxisCount: isTablet ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 1,
                          children: List.generate(8, (index) {
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events,
                                        size: isTablet ? 40 : 32,
                                        color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 4 : 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 1,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: badges.length,
                        itemBuilder: (context, index) {
                          final badge = badges[index];
                          return _buildBadgeCard(badge, isTablet);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(chat_model.Badge badge, bool isTablet) {
    return Card(
      elevation: badge.isEarned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: badge.isEarned
            ? BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _showBadgeDetails(badge);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: isTablet ? 48 : 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: badge.isEarned ? Colors.black87 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (badge.isEarned) ...[
                const SizedBox(height: 4),
                Text(
                  'Earned!',
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 8,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(chat_model.Badge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(badge.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Type: ${badge.type.toString().split('.').last}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badge.requiredValue > 0)
              Text(
                'Required: ${badge.requiredValue}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (badge.earnedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Earned on: ${_formatDate(badge.earnedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
