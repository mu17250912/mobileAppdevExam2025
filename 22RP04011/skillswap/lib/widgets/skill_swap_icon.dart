import 'package:flutter/material.dart';

class SkillSwapIcon extends StatelessWidget {
  final double size;
  const SkillSwapIcon({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
          ),
        ],
      ),
      child: const Icon(
        Icons.swap_horiz,
        size: 100,
        color: Colors.blue,
      ),
    );
  }
}
