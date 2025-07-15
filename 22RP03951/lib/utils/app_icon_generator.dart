import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class AppIconGenerator {
  static Future<void> generateAppIcon() async {
    // Create a 1024x1024 canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(1024, 1024);
    
    // Background gradient (green to lighter green)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2E7D32), // Dark green
          const Color(0xFF4CAF50), // Medium green
          const Color(0xFF66BB6A), // Light green
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw a subtle pattern overlay
    final patternPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw some subtle circles for texture
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(200 + i * 150, 200 + i * 100),
        50 + i * 20,
        patternPaint,
      );
    }
    
    // Main icon: Leaf/Plant symbol
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw a stylized leaf/plant icon
    final path = Path();
    
    // Main leaf shape
    path.moveTo(512, 300);
    path.quadraticBezierTo(400, 200, 300, 300);
    path.quadraticBezierTo(350, 400, 512, 500);
    path.quadraticBezierTo(674, 400, 724, 300);
    path.quadraticBezierTo(624, 200, 512, 300);
    
    // Stem
    path.moveTo(512, 500);
    path.lineTo(512, 700);
    path.lineTo(480, 700);
    path.lineTo(480, 500);
    path.close();
    
    canvas.drawPath(path, iconPaint);
    
    // Add some smaller leaves
    final smallLeafPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Left small leaf
    final leftLeaf = Path();
    leftLeaf.moveTo(350, 400);
    leftLeaf.quadraticBezierTo(300, 350, 250, 400);
    leftLeaf.quadraticBezierTo(300, 450, 350, 400);
    canvas.drawPath(leftLeaf, smallLeafPaint);
    
    // Right small leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(674, 400);
    rightLeaf.quadraticBezierTo(724, 350, 774, 400);
    rightLeaf.quadraticBezierTo(724, 450, 674, 400);
    canvas.drawPath(rightLeaf, smallLeafPaint);
    
    // Add a subtle glow effect
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawCircle(const Offset(512, 400), 200, glowPaint);
    
    // Finish recording
    final picture = recorder.endRecording();
    final image = await picture.toImage(1024, 1024);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Save the icon
    final file = File('assets/images/app_icon.png');
    await file.writeAsBytes(bytes);
    
    print('App icon generated successfully!');
  }
}

// Simple app icon widget for preview
class AppIconWidget extends StatelessWidget {
  const AppIconWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
          ],
        ),
      ),
      child: const Icon(
        Icons.eco,
        color: Colors.white,
        size: 50,
      ),
    );
  }
} 