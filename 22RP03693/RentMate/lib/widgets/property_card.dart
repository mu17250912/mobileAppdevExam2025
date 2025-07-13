import 'package:flutter/material.dart';
import '../models/property.dart';
import '../utils/theme.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onTap;
  final bool isLandlord;
  final bool isPremiumLandlord;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewBookings;

  const PropertyCard({
    super.key,
    required this.property,
    this.isFavorite = false,
    this.onFavorite,
    this.onTap,
    this.isLandlord = false,
    this.isPremiumLandlord = false,
    this.onEdit,
    this.onDelete,
    this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Container(
                height: 200,
                width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: property.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(property.images.first),
                              fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: property.images.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.home,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                  ),
                
                // Premium badge for landlord
                if (isLandlord && isPremiumLandlord)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                
                // Favorite button
                if (onFavorite != null)
                    Positioned(
                      top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                
                // Price tag
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                        ),
                    child: Text(
                      'RWF ${property.monthlyRent.toStringAsFixed(0)}/month',
                      style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                        fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: AppTheme.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                      Text(
                            property.rating.toString(),
                            style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                            ),
                        ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.textSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: AppTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Property details
                  Row(
                    children: [
                      _buildPropertyFeature(
                        icon: Icons.bed,
                        text: '${property.bedrooms} beds',
                      ),
                      const SizedBox(width: 16),
                      _buildPropertyFeature(
                        icon: Icons.bathtub_outlined,
                        text: '${property.bathrooms} baths',
                      ),
                        const SizedBox(width: 16),
                      _buildPropertyFeature(
                        icon: Icons.square_foot,
                        text: '${property.squareFootage} sqft',
                      ),
                      ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Amenities
                  if (property.amenities.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: property.amenities.take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            amenity,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Status for landlord
                  if (isLandlord)
                  Row(
                    children: [
                      Icon(
                          property.isAvailable ? Icons.check_circle : Icons.cancel,
                          color: property.isAvailable ? Colors.green : Colors.red,
                          size: 18,
                      ),
                        const SizedBox(width: 6),
                      Text(
                          property.isAvailable ? 'Available' : 'Booked',
                          style: TextStyle(
                            color: property.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (isLandlord) const SizedBox(height: 12),
                  // Action buttons
                  if (isLandlord)
                    Row(
                      children: [
                        Expanded(
                          child: AppTheme.buildButton(
                            text: 'View Bookings',
                            onPressed: onViewBookings ?? () {},
                            isPrimary: true,
                            icon: Icons.list_alt,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Property',
                          onPressed: onEdit ?? () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Property',
                          onPressed: onDelete ?? () {},
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppTheme.buildButton(
                            text: 'View Details',
                            onPressed: onTap ?? () {},
                            isPrimary: true,
                            icon: Icons.visibility_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Book now functionality
                            },
                            icon: const Icon(
                              Icons.book_online,
                              color: AppTheme.successColor,
                            ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFeature({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textSecondaryColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }
} 