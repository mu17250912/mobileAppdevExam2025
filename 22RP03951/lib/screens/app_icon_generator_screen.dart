import 'package:flutter/material.dart';
import '../utils/app_icon_generator.dart';
import '../theme/app_colors.dart';

class AppIconGeneratorScreen extends StatefulWidget {
  const AppIconGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<AppIconGeneratorScreen> createState() => _AppIconGeneratorScreenState();
}

class _AppIconGeneratorScreenState extends State<AppIconGeneratorScreen> {
  bool _isGenerating = false;
  bool _isGenerated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Generator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'App Icon Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Icon preview
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF4CAF50),
                            Color(0xFF66BB6A),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Design Features:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    _buildFeatureItem('🌱 Green gradient background'),
                    _buildFeatureItem('🌿 Clean leaf/plant icon'),
                    _buildFeatureItem('⚪ White icon for contrast'),
                    _buildFeatureItem('🔲 Rounded corners'),
                    _buildFeatureItem('✨ Subtle glow effect'),
                    
                    const SizedBox(height: 20),
                    
                    if (_isGenerated)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'App icon generated successfully!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateIcon,
              icon: _isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.create),
              label: Text(_isGenerating ? 'Generating...' : 'Generate App Icon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isGenerated ? _buildApk : null,
              icon: const Icon(Icons.android),
              label: const Text('Build APK with New Icon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGenerated ? Colors.orange : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Click "Generate App Icon" to create the new icon\n'
                      '2. The icon will be saved to assets/images/app_icon.png\n'
                      '3. Click "Build APK" to create the APK with the new icon\n'
                      '4. The new APK will have a clean, professional-looking icon',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _generateIcon() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      await AppIconGenerator.generateAppIcon();
      setState(() {
        _isGenerated = true;
        _isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App icon generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buildApk() async {
    // This would typically run a build command
    // For now, we'll just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Run: flutter build apk --release'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
} 