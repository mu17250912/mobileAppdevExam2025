import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final bool showFavoriteButton;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360, // Increased from 340 to resolve overflow
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              _buildImageSection(),
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSizes.sm),
                      _buildTitle(),
                      const SizedBox(height: AppSizes.xs),
                      _buildLocation(),
                      const SizedBox(height: AppSizes.sm),
                      _buildDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withOpacity(0.1),
          ),
          child: property.images.isNotEmpty
              ? Image.network(
                  property.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.textTertiary.withOpacity(0.1),
                      child: Icon(
                        Icons.home,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                    );
                  },
                )
              : Container(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  child: Icon(
                    Icons.home,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                ),
        ),
        
        // Status badges
        Positioned(
          top: AppSizes.sm,
          left: AppSizes.sm,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  property.listingTypeDisplay,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (property.isFeatured) ...[
                const SizedBox(width: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    'Featured',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Favorite button
        if (showFavoriteButton)
          Positioned(
            top: AppSizes.sm,
            right: AppSizes.sm,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isFavorite = authProvider.isFavorite(property.id);
                return GestureDetector(
                  onTap: () {
                    if (isFavorite) {
                      authProvider.removeFromFavorites(property.id);
                    } else {
                      authProvider.addToFavorites(property.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Image count indicator
        if (property.images.length > 1)
          Positioned(
            bottom: AppSizes.sm,
            right: AppSizes.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '+${property.images.length - 1}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          property.formattedPrice,
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          property.propertyTypeDisplay,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      property.title,
      style: AppTextStyles.body1.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.xs),
        Expanded(
          child: Text(
            property.address,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        _buildDetailChip(
          icon: Icons.bed,
          label: '${property.bedrooms}',
        ),
        const SizedBox(width: AppSizes.sm),
        _buildDetailChip(
          icon: Icons.bathtub_outlined,
          label: '${property.bathrooms}',
        ),
        const SizedBox(width: AppSizes.sm),
        _buildDetailChip(
          icon: Icons.square_foot,
          label: property.formattedArea,
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
} 