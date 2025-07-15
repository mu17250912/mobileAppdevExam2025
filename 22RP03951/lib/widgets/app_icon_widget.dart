import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppIconWidget extends StatelessWidget {
  final double size;
  final bool showBorder;

  const AppIconWidget({
    Key? key,
    this.size = 1024,
    this.showBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: size * 0.02,
              )
            : null,
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

class AppIconPreview extends StatelessWidget {
  const AppIconPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('App Icon Preview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AgriConnect App Icon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const AppIconWidget(size: 200),
            const SizedBox(height: 32),
            const Text(
              'Green & White Theme',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 