  import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';
import '../farmer_dashboard.dart';
import '../dealer_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _trackScreenView();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _trackScreenView() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await AnalyticsService.trackScreenView('dashboard_screen');
      await AnalyticsService.setUserProperty('user_role', authService.userRole ?? 'unknown');
      await PerformanceService.trackScreenLoad('dashboard_screen');
    } catch (e) {
      // Ignore tracking errors
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Animated gradient background
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50),
                            Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), _fadeAnimation.value)!,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Animated floating background elements
                ...List.generate(12, (index) => _buildBackgroundElement(index)),
                // Main content
                SafeArea(
                  child: _buildDashboardContent(context, authService),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundElement(int index) {
    final random = math.Random(index);
    final x = random.nextDouble() * MediaQuery.of(context).size.width;
    final y = random.nextDouble() * MediaQuery.of(context).size.height;
    final size = random.nextDouble() * 6 + 3;
    final opacity = random.nextDouble() * 0.2 + 0.1;
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: _fadeController.value * 2 * math.pi * (index % 2 == 0 ? 1 : -1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AuthService authService) {
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading dashboard...'),
            ],
          ),
        ),
      );
    }

    String? userRole = authService.userRole;
    if (authService.isAuthenticated && (userRole == null || userRole.isEmpty)) {
      // Assign default role if missing
      userRole = 'farmer';
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final authServiceProvider = Provider.of<AuthService>(context, listen: false);
        await authServiceProvider.updateUserRole('farmer');
      });
    }

    if (userRole == 'farmer') {
      return FarmerDashboard(username: authService.currentUser ?? 'Farmer');
    } else if (userRole == 'dealer') {
      return DealerDashboard(username: authService.currentUser ?? 'Dealer');
    } else {
      return _buildRoleSelectionScreen(context);
    }
  }

  Widget _buildRoleSelectionScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glassmorphic card
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 420,
                minHeight: size.height * 0.6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
                backgroundBlendMode: BlendMode.overlay,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome to UMUHINZI Smart',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please select your role to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Farmer Card
                  _buildRoleCard(
                    context,
                    icon: Icons.agriculture,
                    title: 'Farmer',
                    subtitle: 'Buy agricultural products and get recommendations',
                    color: Colors.orange,
                    onTap: () => _selectRole(context, 'farmer'),
                  ),
                  const SizedBox(height: 24),
                  // Dealer Card
                  _buildRoleCard(
                    context,
                    icon: Icons.store,
                    title: 'Dealer',
                    subtitle: 'Sell products and manage inventory',
                    color: Colors.blue,
                    onTap: () => _selectRole(context, 'dealer'),
                  ),
                ],
              ),
            ),
          ],
        ),
            ),
          );
        }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String role) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserRole(role);
      
      await AnalyticsService.trackEvent('role_selected', parameters: {
        'role': role,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        setState(() {
          // Trigger rebuild with new role
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to update role: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
} 