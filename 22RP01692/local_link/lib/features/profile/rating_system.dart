import 'package:flutter/material.dart';

class RatingSystem extends StatefulWidget {
  final double rating;
  const RatingSystem({required this.rating, super.key});

  @override
  State<RatingSystem> createState() => _RatingSystemState();
}

class _RatingSystemState extends State<RatingSystem> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _currentRating = index + 1.0;
            });
          },
        );
      }),
    );
  }
} 