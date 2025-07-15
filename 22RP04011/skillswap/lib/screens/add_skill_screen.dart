import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_model.dart';
import '../services/app_service.dart';
import '../main.dart';

class AddSkillScreen extends StatefulWidget {
  final Skill? skillToEdit; // Add parameter for editing

  const AddSkillScreen({super.key, this.skillToEdit});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String _selectedCategory = 'Programming';
  String _selectedDifficulty = 'Beginner';
  final List<String> _selectedTags = [];
  final bool _isLoading = false;
  bool _isSubmitting = false;

  // Check if we're editing
  bool get isEditing => widget.skillToEdit != null;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    // Pre-fill fields if editing
    if (isEditing) {
      final skill = widget.skillToEdit!;
      _nameController.text = skill.name;
      _descriptionController.text = skill.description;
      _locationController.text = skill.location;
      _hourlyRateController.text =
          skill.hourlyRate > 0 ? skill.hourlyRate.toString() : '';
      _selectedCategory = skill.category;
      _selectedDifficulty = skill.difficulty;
      _selectedTags.addAll(skill.tags);
    }
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    final subscriptionStatus = data?['subscriptionStatus'] as String?;
    final subscriptionExpiry = data?['subscriptionExpiry'] as Timestamp?;
    bool hasActiveSubscription = false;
    if (subscriptionStatus == 'active' && subscriptionExpiry != null) {
      final expiryDate = subscriptionExpiry.toDate();
      hasActiveSubscription = expiryDate.isAfter(DateTime.now());
    }
    if (!hasActiveSubscription && mounted) {
      Navigator.pushReplacementNamed(context, '/subscription');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<String?> _getUserName(User user) async {
    // Prefer displayName, fallback to Firestore fullName
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null &&
        data['fullName'] != null &&
        data['fullName'].toString().isNotEmpty) {
      return data['fullName'];
    }
    return null;
  }

  Future<void> _addSkill() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Get user name from displayName or Firestore
      final userName = await _getUserName(user);
      if (userName == null || userName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Warning: Your profile is missing a name. Please update your profile for better visibility.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Continue to allow skill addition
      }

      bool success;
      String actionText;

      if (isEditing) {
        // Update existing skill
        final updatedSkill = widget.skillToEdit!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          tags: _selectedTags,
          location: _locationController.text.trim(),
          hourlyRate: _parseHourlyRate(_hourlyRateController.text),
          updatedAt: DateTime.now(),
        );

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Updating your skill...'),
                ],
              ),
            ),
          );
        }

        success = await AppService.updateSkill(updatedSkill);
        actionText = 'updated';
      } else {
        // Create new skill object
        final skill = Skill(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
          tags: _selectedTags,
          userId: user.uid,
          userName: userName ?? '',
          userPhotoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          location: _locationController.text.trim(),
          hourlyRate: _parseHourlyRate(_hourlyRateController.text),
          languages: const ['English'], // Default language
          availability: 'Available',
          isActive: true,
        );

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Adding your skill...'),
                ],
              ),
            ),
          );
        }

        success = await AppService.addSkill(skill);
        actionText = 'added';
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Skill "${_nameController.text.trim()}" $actionText successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        // Navigate to main scaffold with profile tab selected
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const MainScaffold(initialTabIndex: 3)),
          (route) => route.isFirst,
        );
      } else {
        throw Exception(
            'Failed to ${isEditing ? 'update' : 'add'} skill. Please check your connection and try again.');
      }
    } on FirebaseException catch (e) {
      print('Firebase error code: ${e.code}');
      print('Firebase error message: ${e.message}');
      _handleFirebaseError(e, showActualError: true);
    } catch (e) {
      print('General error: $e');
      _handleGeneralError(e.toString(), showActualError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  double _parseHourlyRate(String rate) {
    if (rate.trim().isEmpty) return 0.0;
    final parsed = double.tryParse(rate.trim());
    if (parsed == null || parsed < 0) {
      throw Exception('Please enter a valid hourly rate (e.g., 25.00)');
    }
    return parsed;
  }

  void _handleFirebaseError(FirebaseException e,
      {bool showActualError = false}) {
    String message = showActualError
        ? 'Firestore error: ${e.message ?? e.code}'
        : 'Failed to add skill. Please check your connection and try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleGeneralError(String error, {bool showActualError = false}) {
    String message = showActualError
        ? 'Error: ${error.toString()}'
        : 'Failed to add skill. Please check your connection and try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addTag() {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.label, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Add Tag',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tagController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter a tag (e.g., JavaScript, React)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        setState(() {
                          _selectedTags.add(value.trim());
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          final value = tagController.text.trim();
                          if (value.isNotEmpty) {
                            setState(() {
                              _selectedTags.add(value);
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isSubmitting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Skill Name *',
                      hintText: 'e.g., JavaScript Programming',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a skill name';
                      }
                      if (value.trim().length < 3) {
                        return 'Skill name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText:
                          'Describe what you can teach about this skill...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category and Difficulty Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: SkillCategories.categories
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          items: SkillCategories.difficulties
                              .map((difficulty) => DropdownMenuItem(
                                    value: difficulty,
                                    child: Text(difficulty),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._selectedTags.map((tag) => Chip(
                                label: Text(tag),
                                onDeleted: () => _removeTag(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              )),
                          ActionChip(
                            label: const Text('+ Add Tag'),
                            onPressed: _addTag,
                            avatar: const Icon(Icons.add, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., Online, New York, Remote',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hourly Rate
                  TextFormField(
                    controller: _hourlyRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (Optional)',
                      hintText: '0.00 (Leave empty for free)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final rate = double.tryParse(value.trim());
                        if (rate == null || rate < 0) {
                          return 'Please enter a valid hourly rate';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _addSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Adding...'),
                              ],
                            )
                          : Text(
                              isEditing ? 'Update Skill' : 'Add Skill',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your skill will be stored in Firebase and visible to other users who can request learning sessions.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
          );
  }
}
