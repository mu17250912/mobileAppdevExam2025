import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Consumer2<AuthProvider, PropertyProvider>(
        builder: (context, authProvider, propertyProvider, child) {
          if (propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authProvider.isAuthenticated) {
            return _buildLoginPrompt();
          }

          final favoriteProperties = propertyProvider.properties
              .where((property) => authProvider.isFavorite(property.id))
              .toList();

          if (favoriteProperties.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: favoriteProperties.length,
            itemBuilder: (context, index) {
              final property = favoriteProperties[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < favoriteProperties.length - 1 ? AppSizes.sm : 0,
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
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Sign in to save favorites',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Create an account to save and manage your favorite properties',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to login screen
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No favorites yet',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Start exploring properties and save your favorites',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: () {
              // Pop to root (MainScreen)
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Use a post-frame callback to set the search tab if MainScreen exposes a static method or via a provider
              // For now, send a notification that MainScreen can listen to
              // (You can implement a more robust solution with a provider or event bus if needed)
              // Example: EventBus or Provider can be used for better UX
              // TODO: Implement robust navigation if needed
            },
            child: const Text('Explore Properties'),
          ),
        ],
      ),
    );
  }
} 