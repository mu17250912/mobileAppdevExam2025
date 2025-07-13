import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;

  const RatingStars({required this.rating, this.maxStars = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }
} 