import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_upgrade_dialog.dart';
import 'premium_features_summary.dart';

class SavingGoalsScreen extends StatefulWidget {
  final void Function(int)? onRequirePremium;
  const SavingGoalsScreen({super.key, this.onRequirePremium});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _goals = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime? _targetDate;
  String _selectedCategory = 'General';
  final PremiumFeaturesManager _premiumManager = PremiumFeaturesManager();
  bool _savingGoalsUnlocked = false;

  final List<String> _categories = [
    'General',
    'Emergency Fund',
    'Vacation',
    'Home',
    'Car',
    'Education',
    'Wedding',
    'Business',
    'Investment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _checkSavingGoalsUnlocked();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[SavingGoals] Loading goals for user: ${user.uid}');
        
        // Simplified query without orderBy to avoid potential issues
        final querySnapshot = await FirebaseFirestore.instance
            .collection('saving_goals')
            .where('userId', isEqualTo: user.uid)
            .get();

        print('[SavingGoals] Found ${querySnapshot.docs.length} goals');
        
        setState(() {
          _goals = querySnapshot.docs.map((doc) {
            final data = doc.data();
            final goal = {
              'id': doc.id,
              'title': data['title'] ?? '',
              'targetAmount': data['targetAmount'] ?? 0.0,
              'currentAmount': data['currentAmount'] ?? 0.0,
              'targetDate': data['targetDate'] as Timestamp?,
              'category': data['category'] ?? 'General',
              'createdAt': data['createdAt'] as Timestamp?,
              'isCompleted': data['isCompleted'] ?? false,
            };
            print('[SavingGoals] Loaded goal: ${goal['title']} (ID: ${goal['id']})');
            return goal;
          }).toList();
          
          // Sort goals by creation date (newest first) in memory
          _goals.sort((a, b) {
            final aCreated = a['createdAt'] as Timestamp?;
            final bCreated = b['createdAt'] as Timestamp?;
            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;
            return bCreated.compareTo(aCreated);
          });
        });
        
        print('[SavingGoals] Total goals loaded: ${_goals.length}');
        
        // Show feedback to user
        if (mounted && _goals.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${_goals.length} saving goal(s)', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('[SavingGoals] No user authenticated, cannot load goals');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to view your goals', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      print('[SavingGoals] Error loading goals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading goals: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkIsPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['isPremium'] ?? false);
  }

  Future<void> _checkSavingGoalsUnlocked() async {
    final unlocked = await _premiumManager.isFeatureUnlocked('savingGoals');
    setState(() {
      _savingGoalsUnlocked = unlocked;
    });
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock Saving Goals'),
        content: Text('This is a premium feature. Please pay to unlock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _premiumManager.unlockFeature('savingGoals');
              await _checkSavingGoalsUnlocked();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saving Goals unlocked!')),
              );
            },
            child: Text('Pay & Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGoal() async {
    print('[SavingGoals] Attempting to add goal...');
    if (!_savingGoalsUnlocked) {
      print('[SavingGoals] Feature not unlocked.');
      _showPaywall();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      print('[SavingGoals] Validation failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields correctly.', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_targetDate == null) {
      print('[SavingGoals] Target date not set.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a target date', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[SavingGoals] User authenticated: ${user.uid}');
        print('[SavingGoals] Saving to Firestore collection: saving_goals');
        
        final goalData = {
          'userId': user.uid,
          'title': _titleController.text.trim(),
          'targetAmount': double.parse(_targetAmountController.text),
          'currentAmount': double.parse(_currentAmountController.text),
          'targetDate': Timestamp.fromDate(_targetDate!),
          'category': _selectedCategory,
          'createdAt': FieldValue.serverTimestamp(),
          'isCompleted': false,
        };
        
        print('[SavingGoals] Goal data to save: $goalData');
        
        final docRef = await FirebaseFirestore.instance.collection('saving_goals').add(goalData);
        print('[SavingGoals] Goal saved successfully with ID: ${docRef.id}');
        
        // Clear form
        _titleController.clear();
        _targetAmountController.clear();
        _currentAmountController.clear();
        _targetDate = null;
        _selectedCategory = 'General';

        // Reload goals to show the new one
        await _loadGoals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal added successfully! Check your goals below.', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('[SavingGoals] No user authenticated');
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('[SavingGoals] Error saving goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add goal: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGoalAmount(String goalId, double newAmount) async {
    try {
      await FirebaseFirestore.instance
          .collection('saving_goals')
          .doc(goalId)
          .update({
        'currentAmount': newAmount,
        'isCompleted': newAmount >= _goals.firstWhere((g) => g['id'] == goalId)['targetAmount'],
      });

      await _loadGoals();
    } catch (e) {
      print('Error updating goal: $e');
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saving_goals')
          .doc(goalId)
          .delete();

      await _loadGoals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal deleted successfully!', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete goal: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Saving Goals',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showAddGoalDialog(),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _loadGoals(),
          ),
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showDebugInfo(),
          ),
          IconButton(
            icon: Icon(
              Icons.science,
              color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _createTestGoal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return _buildGoalCard(goal);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Saving Goals Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start setting financial goals to track your progress',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Goal'),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final targetAmount = goal['targetAmount'] as double;
    final currentAmount = goal['currentAmount'] as double;
    final progress = targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final isCompleted = goal['isCompleted'] as bool;
    final targetDate = goal['targetDate'] as Timestamp?;
    final daysLeft = targetDate != null 
        ? targetDate.toDate().difference(DateTime.now()).inDays 
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteGoal(goal['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Goal'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(goal['category']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal['category'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _getCategoryColor(goal['category']),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        '${currentAmount.toStringAsFixed(0)} FRW',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        '${targetAmount.toStringAsFixed(0)} FRW',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (daysLeft != null)
                  Text(
                    daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: daysLeft > 0 
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isCompleted)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: currentAmount.toString(),
                      decoration: InputDecoration(
                        labelText: 'Update Amount',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (value) {
                        final newAmount = double.tryParse(value) ?? currentAmount;
                        _updateGoalAmount(goal['id'], newAmount);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // This would be handled by the TextFormField onFieldSubmitted
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            if (isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Goal Achieved! 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Goal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a goal title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (FRW)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter target amount';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Current Amount (FRW)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _targetDate != null 
                        ? 'Target Date: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                        : 'Select Target Date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => _targetDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              Navigator.of(context).pop();
              _addGoal();
            },
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Emergency Fund':
        return Colors.red;
      case 'Vacation':
        return Colors.blue;
      case 'Home':
        return Colors.green;
      case 'Car':
        return Colors.orange;
      case 'Education':
        return Colors.purple;
      case 'Wedding':
        return Colors.pink;
      case 'Business':
        return Colors.teal;
      case 'Investment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _createTestGoal() async {
    print('[SavingGoals] Attempting to create a test goal...');
    if (!_savingGoalsUnlocked) {
      print('[SavingGoals] Feature not unlocked.');
      _showPaywall();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[SavingGoals] User authenticated: ${user.uid}');
        print('[SavingGoals] Saving test goal to Firestore collection: saving_goals');
        
        final testGoalData = {
          'userId': user.uid,
          'title': 'Test Goal ${DateTime.now().millisecondsSinceEpoch}',
          'targetAmount': 100000.0, // 100,000 FRW
          'currentAmount': 0.0,
          'targetDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          'category': 'General',
          'createdAt': FieldValue.serverTimestamp(),
          'isCompleted': false,
        };
        
        print('[SavingGoals] Test goal data to save: $testGoalData');
        
        final docRef = await FirebaseFirestore.instance.collection('saving_goals').add(testGoalData);
        print('[SavingGoals] Test goal saved successfully with ID: ${docRef.id}');
        
        await _loadGoals();

        if (mounted) {
          _showFirestoreLocationInfo(docRef.id, user.uid);
        }
      } else {
        print('[SavingGoals] No user authenticated for test goal');
        throw Exception('User not authenticated for test goal');
      }
    } catch (e) {
      print('[SavingGoals] Error saving test goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add test goal: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestGoalWithoutPremiumCheck() async {
    print('[SavingGoals] Creating test goal without premium check...');
    
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[SavingGoals] User authenticated: ${user.uid}');
        print('[SavingGoals] Saving test goal to Firestore collection: saving_goals');
        
        final testGoalData = {
          'userId': user.uid,
          'title': 'Test Goal (No Premium Check) ${DateTime.now().millisecondsSinceEpoch}',
          'targetAmount': 50000.0, // 50,000 FRW
          'currentAmount': 0.0,
          'targetDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          'category': 'General',
          'createdAt': FieldValue.serverTimestamp(),
          'isCompleted': false,
        };
        
        print('[SavingGoals] Test goal data to save: $testGoalData');
        
        final docRef = await FirebaseFirestore.instance.collection('saving_goals').add(testGoalData);
        print('[SavingGoals] Test goal saved successfully with ID: ${docRef.id}');
        
        await _loadGoals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test goal created successfully! ID: ${docRef.id}', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('[SavingGoals] No user authenticated for test goal');
        throw Exception('User not authenticated for test goal');
      }
    } catch (e) {
      print('[SavingGoals] Error saving test goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add test goal: ${e.toString()}', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFirestoreLocationInfo(String goalId, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text('Goal Saved Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your test goal has been saved to Firestore.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firestore Location:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 8),
                  Text('Collection: saving_goals'),
                  Text('Document ID: $goalId'),
                  Text('User ID: $userId'),
                  const SizedBox(height: 8),
                  Text(
                    'To view in Firebase Console:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('1. Go to Firebase Console'),
                  Text('2. Select your project'),
                  Text('3. Go to Firestore Database'),
                  Text('4. Look for "saving_goals" collection'),
                  Text('5. Find document with ID: $goalId'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadGoals(); // Reload goals after saving
              },
              child: Text('Refresh Goals List'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current User: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not logged in'}'),
              const SizedBox(height: 8),
              Text('Saving Goals Unlocked: $_savingGoalsUnlocked'),
              const SizedBox(height: 8),
              Text('Total Goals in Memory: ${_goals.length}'),
              const SizedBox(height: 8),
              Text('Goals List:'),
              ..._goals.map((goal) => Text('  - ${goal['title']} (ID: ${goal['id']})')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadGoals();
                },
                child: Text('Force Reload Goals'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _createTestGoalWithoutPremiumCheck();
                },
                child: Text('Create Test Goal (Bypass Premium)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
} 