import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_colors.dart';

class IconGenerator {
  static Widget generateAppIcon({double size = 1024}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.agriculture,
          size: size * 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
} 