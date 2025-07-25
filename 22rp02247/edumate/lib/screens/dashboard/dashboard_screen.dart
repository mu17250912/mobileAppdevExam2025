import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/progress_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_upgrade_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _providersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize providers here - wait for build to complete
  }

  void _initializeProvidersIfNeeded() {
    if (_providersInitialized) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.uid;
      
      // Initialize all providers
      Provider.of<NotesProvider>(context, listen: false).initialize(userId);
      Provider.of<FlashcardProvider>(context, listen: false).initialize(userId);
      Provider.of<QuizProvider>(context, listen: false).initialize(userId);
      
      _providersInitialized = true;
    }
  }

  void _updateProgressProvider() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    
    progressProvider.updateData(
      flashcards: flashcardProvider.flashcards,
      quizAttempts: quizProvider.quizAttempts,
      notes: notesProvider.notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize providers after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvidersIfNeeded();
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('EduMate'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog();
                  } else if (value == 'profile') {
                    _showProfileDialog(authProvider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userName = authProvider.userProfile?.name ?? 'Student';
          final isPremium = authProvider.isPremium;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(userName, isPremium),
                const SizedBox(height: 32),

                // Quick Stats
                _buildQuickStats(),
                const SizedBox(height: 32),

                // Main Options Grid
                _buildMainOptionsGrid(isPremium),
                const SizedBox(height: 32),

                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(String userName, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to continue your learning journey?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Notes',
                '${progressProvider.totalNotes}',
                Icons.note,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Flashcards',
                '${progressProvider.studiedFlashcards}/${progressProvider.totalFlashcards}',
                Icons.flip,
                AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Quizzes',
                '${progressProvider.totalQuizAttempts}',
                Icons.quiz,
                AppTheme.accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptionsGrid(bool isPremium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Tools',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildOptionCard(
              'Notes',
              'Create and organize your study notes',
              Icons.note,
              AppTheme.primaryColor,
              () => Navigator.pushNamed(context, '/notes'),
            ),
            _buildOptionCard(
              'Flashcards',
              'Generate and study flashcards',
              Icons.flip,
              AppTheme.secondaryColor,
              () => Navigator.pushNamed(context, '/flashcards'),
            ),
            _buildOptionCard(
              'Quiz Me',
              'Test your knowledge',
              Icons.quiz,
              AppTheme.accentColor,
              isPremium ? () => Navigator.pushNamed(context, '/quiz') : _showPremiumDialog,
            ),
            _buildOptionCard(
              'Progress',
              'Track your learning progress',
              Icons.trending_up,
              AppTheme.infoColor,
              isPremium ? () => Navigator.pushNamed(context, '/progress') : _showPremiumDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final recentActivity = progressProvider.recentActivity;
        
        if (recentActivity.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivity.length > 5 ? 5 : recentActivity.length,
                itemBuilder: (context, index) {
                  final activity = recentActivity[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _formatActivityTime(activity['timestamp'] as DateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${authProvider.userProfile?.name ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Email: ${authProvider.userProfile?.email ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Premium: ${authProvider.isPremium ? 'Yes' : 'No'}'),
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
}
