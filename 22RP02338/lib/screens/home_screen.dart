import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/category_card.dart';
import 'property_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load properties when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb_auth.User?>(
      stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData;
        return Scaffold(
          body: Consumer<PropertyProvider>(
            builder: (context, propertyProvider, child) {
              if (propertyProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (propertyProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'Error loading properties',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        propertyProvider.error!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      ElevatedButton(
                        onPressed: () => propertyProvider.loadProperties(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  // Main content
                  ListView(
                    padding: const EdgeInsets.all(AppSizes.md),
                    children: [
                      // Welcome Section
                      if (isLoggedIn) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to UMUKOMISIYONERI!',
                                style: AppTextStyles.heading3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                'Find your dream property today',
                                style: AppTextStyles.body1.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // Quick Actions
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: AppColors.textTertiary.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: AppTextStyles.heading4.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.payment,
                                    title: 'Contact Owner',
                                    subtitle: 'Pay \$50 to connect',
                                    color: AppColors.primary,
                                    onTap: () => _showPaymentInfo(context),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.search,
                                    title: 'Search',
                                    subtitle: 'Find properties',
                                    color: AppColors.secondary,
                                    onTap: () => Navigator.pushNamed(context, '/search'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Categories Section
                      _buildCategoriesSection(),
                      const SizedBox(height: AppSizes.lg),

                      // Featured Properties Section
                      _buildFeaturedPropertiesSection(propertyProvider),
                      const SizedBox(height: AppSizes.lg),

                      // Recent Properties Section
                      _buildRecentPropertiesSection(propertyProvider),
                      const SizedBox(height: AppSizes.xl),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UMUKOMISIYONERI',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Discover the perfect property that matches your lifestyle and budget.',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textInverse.withOpacity(0.9),
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textInverse,
                          side: BorderSide(color: AppColors.surface),
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Icon(
            Icons.home,
            size: 48,
            color: AppColors.textInverse.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'type': 'house', 'icon': Icons.home, 'label': 'Houses', 'color': AppColors.primary},
      {'type': 'apartment', 'icon': Icons.apartment, 'label': 'Apartments', 'color': AppColors.success},
      {'type': 'land', 'icon': Icons.landscape, 'label': 'Land', 'color': AppColors.warning},
      {'type': 'commercial', 'icon': Icons.business, 'label': 'Commercial', 'color': AppColors.info},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by Category',
          style: AppTextStyles.heading4.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < categories.length - 1 ? AppSizes.sm : 0,
                ),
                child: CategoryCard(
                  icon: category['icon'] as IconData,
                  label: category['label'] as String,
                  color: category['color'] as Color,
                  onTap: () {
                    // TODO: Navigate to category filter
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPropertiesSection(PropertyProvider propertyProvider) {
    final featuredProperties = propertyProvider.featuredProperties ?? [];

    if (featuredProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Properties',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all featured properties
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 380, // Increased to fit PropertyCard content
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredProperties.length,
            itemBuilder: (context, index) {
              final property = featuredProperties[index];
              if (property == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(
                  right: index < featuredProperties.length - 1 ? AppSizes.sm : 0,
                ),
                child: SizedBox(
                  width: 280,
                  child: PropertyCard(
                    property: property,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailScreen(property: property),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPropertiesSection(PropertyProvider propertyProvider) {
    final recentProperties = (propertyProvider.properties ?? []).take(3).toList();

    if (recentProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Listings',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all properties
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Column(
          children: List.generate(recentProperties.length, (index) {
            final property = recentProperties[index];
            if (property == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < recentProperties.length - 1 ? AppSizes.sm : 0,
              ),
              child: PropertyCard(
                property: property,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(property: property),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSizes.xs),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Property Owners'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To contact property owners directly, you need to pay a \$50 connection fee.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'How it works:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Browse properties on the app'),
            Text('2. Click "Contact Owner" on any property'),
            Text('3. Pay the \$50 connection fee'),
            Text('4. Get connected with the owner within 24 hours'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 