import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // all, studied, unstudied

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFlashcardDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddFlashcardDialog(),
    );
  }

  void _showEditFlashcardDialog(FlashcardModel flashcard) {
    showDialog(
      context: context,
      builder: (context) => EditFlashcardDialog(flashcard: flashcard),
    );
  }

  void _showDeleteConfirmation(FlashcardModel flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text('Are you sure you want to delete this flashcard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FlashcardProvider>(context, listen: false)
                  .deleteFlashcard(flashcard.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<FlashcardModel> _getFilteredFlashcards(List<FlashcardModel> flashcards) {
    List<FlashcardModel> filtered = flashcards;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((flashcard) {
        return flashcard.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               flashcard.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    switch (_filterType) {
      case 'studied':
        filtered = filtered.where((flashcard) => flashcard.isStudied).toList();
        break;
      case 'unstudied':
        filtered = filtered.where((flashcard) => !flashcard.isStudied).toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  hintText: 'Search flashcards...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip('all', 'All'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('unstudied', 'Unstudied'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('studied', 'Studied'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flashcards List
          Expanded(
            child: Consumer<FlashcardProvider>(
              builder: (context, flashcardProvider, child) {
                if (flashcardProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredFlashcards = _getFilteredFlashcards(flashcardProvider.flashcards);

                if (filteredFlashcards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flip_outlined,
                          size: 80,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No flashcards yet' : 'No flashcards found',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Create your first flashcard to get started'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFlashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = filteredFlashcards[index];
                    return _buildFlashcardCard(flashcard);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFlashcardDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFlashcardCard(FlashcardModel flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFlashcardViewer(flashcard),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      flashcard.question,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditFlashcardDialog(flashcard);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(flashcard);
                          break;
                        case 'mark_studied':
                          _markAsStudied(flashcard);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: flashcard.isStudied ? 'mark_unstudied' : 'mark_studied',
                        child: Row(
                          children: [
                            Icon(flashcard.isStudied ? Icons.undo : Icons.check),
                            const SizedBox(width: 8),
                            Text(flashcard.isStudied ? 'Mark Unstudied' : 'Mark Studied'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                flashcard.answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: flashcard.isStudied 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      flashcard.isStudied ? 'Studied' : 'Unstudied',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: flashcard.isStudied ? AppTheme.successColor : AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (flashcard.studyCount > 0) ...[
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${flashcard.studyCount}x',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (flashcard.lastStudiedAt != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(flashcard.lastStudiedAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlashcardViewer(FlashcardModel flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardViewerScreen(flashcard: flashcard),
      ),
    );
  }

  void _markAsStudied(FlashcardModel flashcard) {
    Provider.of<FlashcardProvider>(context, listen: false)
        .markAsStudied(flashcard.id);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class FlashcardViewerScreen extends StatefulWidget {
  final FlashcardModel flashcard;

  const FlashcardViewerScreen({Key? key, required this.flashcard}) : super(key: key);

  @override
  State<FlashcardViewerScreen> createState() => _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState extends State<FlashcardViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _markAsStudied() {
    Provider.of<FlashcardProvider>(context, listen: false)
        .markAsStudied(widget.flashcard.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Flashcard'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          if (!widget.flashcard.isStudied)
            TextButton(
              onPressed: _markAsStudied,
              child: const Text('Mark Studied'),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flashcard
              GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * 3.14159;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: _flipAnimation.value < 0.5
                          ? _buildCardSide(widget.flashcard.question, 'Question')
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(3.14159),
                              child: _buildCardSide(widget.flashcard.answer, 'Answer'),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Instructions
              Text(
                'Tap the card to flip',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Study Stats
              if (widget.flashcard.studyCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.repeat,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Studied ${widget.flashcard.studyCount} time${widget.flashcard.studyCount > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSide(String text, String label) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AddFlashcardDialog extends StatefulWidget {
  const AddFlashcardDialog({Key? key}) : super(key: key);

  @override
  State<AddFlashcardDialog> createState() => _AddFlashcardDialogState();
}

class _AddFlashcardDialogState extends State<AddFlashcardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final success = await flashcardProvider.addFlashcard(
        userId: authProvider.currentUser!.uid,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Flashcard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _questionController,
                labelText: 'Question',
                hintText: 'Enter the question',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _answerController,
                labelText: 'Answer',
                hintText: 'Enter the answer',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an answer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<FlashcardProvider>(
                      builder: (context, flashcardProvider, child) {
                        return CustomButton(
                          text: 'Save',
                          onPressed: flashcardProvider.isLoading ? null : _saveFlashcard,
                          isLoading: flashcardProvider.isLoading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditFlashcardDialog extends StatefulWidget {
  final FlashcardModel flashcard;

  const EditFlashcardDialog({Key? key, required this.flashcard}) : super(key: key);

  @override
  State<EditFlashcardDialog> createState() => _EditFlashcardDialogState();
}

class _EditFlashcardDialogState extends State<EditFlashcardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.flashcard.question);
    _answerController = TextEditingController(text: widget.flashcard.answer);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _updateFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);
    final success = await flashcardProvider.updateFlashcard(
      flashcardId: widget.flashcard.id,
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcard updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Flashcard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _questionController,
                labelText: 'Question',
                hintText: 'Enter the question',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _answerController,
                labelText: 'Answer',
                hintText: 'Enter the answer',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an answer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<FlashcardProvider>(
                      builder: (context, flashcardProvider, child) {
                        return CustomButton(
                          text: 'Update',
                          onPressed: flashcardProvider.isLoading ? null : _updateFlashcard,
                          isLoading: flashcardProvider.isLoading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 