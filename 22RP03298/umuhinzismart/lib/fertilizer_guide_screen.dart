import 'package:flutter/material.dart';
import 'fertilizer_recommendation_screen.dart';
import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'widgets/loading_widget.dart';
import 'widgets/error_widget.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FertilizerGuideScreen extends StatefulWidget {
  const FertilizerGuideScreen({super.key});

  @override
  State<FertilizerGuideScreen> createState() => _FertilizerGuideScreenState();
}

class _FertilizerGuideScreenState extends State<FertilizerGuideScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCrop;
  String? _selectedWeek;
  final _areaController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late DateTime _loadStart;

  List<String> _crops = ['Maize', 'Beans', 'Potatoes', 'Tomatoes'];
  List<String> _weeks = ['Week 1-2', 'Week 3-4', 'Week 5-6', 'Flowering Stage'];
  bool _isDropdownLoading = true;
  String? _dropdownError;
  List<Map<String, dynamic>> _allRecommendations = [];

  @override
  void initState() {
    super.initState();
    _loadStart = DateTime.now();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    AnalyticsService.trackFeatureUsage(
      feature: 'fertilizer_guide_view',
      userRole: 'farmer',
    );
    PerformanceService.trackScreenLoad('fertilizer_guide_screen', loadTimeMs: 0);
    _fetchDropdownOptions();
  }

  Future<void> _fetchDropdownOptions() async {
    setState(() {
      _isDropdownLoading = true;
      _dropdownError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance.collection('fertilizer_recommendations').get();
      _allRecommendations = snap.docs.map((doc) => doc.data()).toList();
      final crops = _allRecommendations.map((d) => d['crop']?.toString() ?? '').where((c) => c.isNotEmpty).toSet().toList();
      if (crops.isNotEmpty) _crops = crops;
      setState(() {
        _isDropdownLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDropdownLoading = false;
        _dropdownError = 'Failed to load crop/week options: $e';
      });
    }
  }

  List<String> _getWeeksForSelectedCrop() {
    if (_selectedCrop == null) return [];
    final weeks = _allRecommendations
        .where((rec) => rec['crop'] == _selectedCrop)
        .map((rec) => rec['week']?.toString() ?? '')
        .where((w) => w.isNotEmpty)
        .toSet()
        .toList();
    return weeks;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      AnalyticsService.trackFeatureUsage(
        feature: 'fertilizer_guide_submit',
        userRole: 'farmer',
        additionalData: 'crop=$_selectedCrop,week=$_selectedWeek,area=${_areaController.text}',
      );
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate processing
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FertilizerRecommendationScreen(
            crop: _selectedCrop!,
            week: _selectedWeek!,
            area: _areaController.text,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit: $e';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Fertilizer Guide'),
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.science, color: Color(0xFF4CAF50), size: 32),
                            const SizedBox(width: 12),
                            Text('Get a custom recommendation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (_dropdownError != null)
                          CustomErrorWidget(message: _dropdownError!),
                        if (_isDropdownLoading)
                          const LoadingWidget(message: 'Loading options...'),
                        if (!_isDropdownLoading && _dropdownError == null) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            decoration: const InputDecoration(
                              labelText: 'Crop Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.eco),
                            ),
                            items: _crops.map((crop) => DropdownMenuItem(value: crop, child: Text(crop))).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCrop = value;
                                _selectedWeek = null; // Reset week when crop changes
                              });
                            },
                            validator: (value) => value == null ? 'Please select a crop' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedWeek,
                            decoration: const InputDecoration(
                              labelText: 'Crop Week',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            items: _getWeeksForSelectedCrop().map((week) => DropdownMenuItem(value: week, child: Text(week))).toList(),
                            onChanged: (value) => setState(() => _selectedWeek = value),
                            validator: (value) => value == null ? 'Please select a week' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Area (e.g., 1 acre)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.square_foot),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter the area' : null,
                          ),
                          const SizedBox(height: 40),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CustomErrorWidget(
                                message: _errorMessage!,
                                icon: Icons.error_outline,
                                color: Colors.red,
                              ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _isSubmitting
                                ? LoadingButton(
                                    text: 'Submitting...',
                                    isLoading: true,
                                    backgroundColor: Colors.yellow,
                                    textColor: Colors.black,
                                  )
                                : ElevatedButton(
                                    key: const ValueKey('submit_btn'),
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.yellow,
                                      foregroundColor: Colors.black,
                                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Submit'),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 