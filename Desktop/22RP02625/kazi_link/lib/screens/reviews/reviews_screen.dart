import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviews = [
      {'reviewer': 'John', 'rating': 5, 'comment': 'Great job!'},
      {'reviewer': 'Mary', 'rating': 4, 'comment': 'Very professional.'},
      {'reviewer': 'Alex', 'rating': 5, 'comment': 'Highly recommended!'},
    ];
    final avgRating = (reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int)) / reviews.length).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.star, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Ratings & Reviews',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 40),
                  const SizedBox(width: 8),
                  Text(
                    'Average Rating: $avgRating',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Reviews:',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index] as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            review['reviewer'][0],
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          review['reviewer'],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          review['comment'],
                          style: GoogleFonts.poppins(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.8)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 2),
                            Text(
                              '${review['rating']}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 