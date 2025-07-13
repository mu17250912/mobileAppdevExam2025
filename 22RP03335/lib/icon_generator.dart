import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  // Create a 1024x1024 image
  final image = img.Image(width: 1024, height: 1024);
  
  // Fill with gradient background (purple to blue)
  for (int y = 0; y < 1024; y++) {
    for (int x = 0; x < 1024; x++) {
      final progress = (x + y) / (1024 + 1024);
      final r = (143 + (106 - 143) * progress).round(); // 8F to 6A
      final g = (92 + (130 - 92) * progress).round();   // 5C to 82
      final b = (255 + (251 - 255) * progress).round(); // FF to FB
      image.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  // Draw microphone body (white rectangle)
  final micX = 432;
  final micY = 300;
  final micWidth = 160;
  final micHeight = 300;
  
  // Microphone body
  for (int y = micY; y < micY + micHeight; y++) {
    for (int x = micX; x < micX + micWidth; x++) {
      if (x >= 0 && x < 1024 && y >= 0 && y < 1024) {
        image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
  }
  
  // Microphone head (ellipse)
  final headX = 512;
  final headY = 280;
  final headRadiusX = 100;
  final headRadiusY = 60;
  
  for (int y = headY - headRadiusY; y < headY + headRadiusY; y++) {
    for (int x = headX - headRadiusX; x < headX + headRadiusX; x++) {
      final dx = (x - headX) / headRadiusX;
      final dy = (y - headY) / headRadiusY;
      if (dx * dx + dy * dy <= 1 && x >= 0 && x < 1024 && y >= 0 && y < 1024) {
        image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
  }
  
  // Microphone stand
  final standX = 502;
  final standY = 600;
  final standWidth = 20;
  final standHeight = 150;
  
  for (int y = standY; y < standY + standHeight; y++) {
    for (int x = standX; x < standX + standWidth; x++) {
      if (x >= 0 && x < 1024 && y >= 0 && y < 1024) {
        image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
  }
  
  // Stand base (ellipse)
  final baseX = 512;
  final baseY = 750;
  final baseRadiusX = 80;
  final baseRadiusY = 20;
  
  for (int y = baseY - baseRadiusY; y < baseY + baseRadiusY; y++) {
    for (int x = baseX - baseRadiusX; x < baseX + baseRadiusX; x++) {
      final dx = (x - baseX) / baseRadiusX;
      final dy = (y - baseY) / baseRadiusY;
      if (dx * dx + dy * dy <= 1 && x >= 0 && x < 1024 && y >= 0 && y < 1024) {
        image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
  }
  
  // Draw laughing faces (golden circles)
  final facePositions = [
    [200, 200], [824, 200], [200, 824], [824, 824]
  ];
  
  for (final pos in facePositions) {
    final faceX = pos[0];
    final faceY = pos[1];
    final faceRadius = 40;
    
    for (int y = faceY - faceRadius; y < faceY + faceRadius; y++) {
      for (int x = faceX - faceRadius; x < faceX + faceRadius; x++) {
        final dx = x - faceX;
        final dy = y - faceY;
        if (dx * dx + dy * dy <= faceRadius * faceRadius && x >= 0 && x < 1024 && y >= 0 && y < 1024) {
          image.setPixel(x, y, img.ColorRgb8(255, 215, 0)); // Gold color
        }
      }
    }
  }
  
  // Save the image
  final pngBytes = img.encodePng(image);
  final file = File('assets/app_icon_1024.png');
  await file.writeAsBytes(pngBytes);
  
  print('App icon generated successfully at: assets/app_icon_1024.png');
} 