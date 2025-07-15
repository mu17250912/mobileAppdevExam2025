import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingUtils {
  // Fetch average rating for a course
  static Future<double> getCourseAverageRating(String courseId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('course_ratings')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      if (snap.docs.isEmpty) return 0.0;
      
      final ratings = snap.docs.map((doc) => doc.data()['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('Error fetching course rating: $e');
      return 0.0;
    }
  }

  // Fetch average rating for a trainer
  static Future<double> getTrainerAverageRating(String trainerEmail) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('trainer_ratings')
          .where('trainerEmail', isEqualTo: trainerEmail)
          .get();
      
      if (snap.docs.isEmpty) return 0.0;
      
      final ratings = snap.docs.map((doc) => doc.data()['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('Error fetching trainer rating: $e');
      return 0.0;
    }
  }

  // Widget to display rating with stars
  static Widget buildRatingDisplay(double rating, {double size = 16}) {
    if (rating == 0.0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, color: Colors.grey, size: size),
          const SizedBox(width: 4),
          Text(
            'No ratings',
            style: GoogleFonts.poppins(
              fontSize: size * 0.6,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: GoogleFonts.poppins(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // FutureBuilder widget for course rating
  static Widget buildCourseRatingWidget(String courseId, {double size = 16}) {
    return FutureBuilder<double>(
      future: getCourseAverageRating(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size * 2,
            height: size,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
          );
        }
        return buildRatingDisplay(snapshot.data ?? 0.0, size: size);
      },
    );
  }

  // FutureBuilder widget for trainer rating
  static Widget buildTrainerRatingWidget(String trainerEmail, {double size = 16}) {
    return FutureBuilder<double>(
      future: getTrainerAverageRating(trainerEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size * 2,
            height: size,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
          );
        }
        return buildRatingDisplay(snapshot.data ?? 0.0, size: size);
      },
    );
  }
} 