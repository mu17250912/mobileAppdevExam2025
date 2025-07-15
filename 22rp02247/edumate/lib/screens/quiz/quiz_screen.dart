import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/premium_upgrade_dialog.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizModel? _currentQuiz;
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {};
  bool _isQuizStarted = false;
  bool _isQuizCompleted = false;
  DateTime? _quizStartTime;

  @override
  void initState() {
    super.initState();
    // Ensure providers are initialized when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      print('DEBUG: Initializing providers for user: ${authProvider.currentUser!.uid}');
      
      if (!quizProvider.isInitialized) {
        print('DEBUG: Initializing QuizProvider');
        quizProvider.initialize(authProvider.currentUser!.uid);
      }
      
      if (!flashcardProvider.isInitialized) {
        print('DEBUG: Initializing FlashcardProvider');
        flashcardProvider.initialize(authProvider.currentUser!.uid);
      }
    } else {
      print('DEBUG: No current user found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Consumer<FlashcardProvider>(
        builder: (context, flashcardProvider, child) {
          // Debug information
          print('DEBUG: FlashcardProvider state - isLoading: ${flashcardProvider.isLoading}, flashcards: ${flashcardProvider.flashcards.length}');
          
          if (flashcardProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading flashcards...'),
                ],
              ),
            );
          }

          if (flashcardProvider.flashcards.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 80,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Flashcards Found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You need to create at least one flashcard before you can take a quiz.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Go to Flashcards',
                      onPressed: () => Navigator.pushNamed(context, '/flashcards'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_isQuizStarted) {
            return _buildQuizStartScreen(flashcardProvider);
          }

          if (_isQuizCompleted) {
            return _buildQuizResultsScreen();
          }

          return _buildQuizQuestionScreen();
        },
      ),
    );
  }

  Widget _buildQuizStartScreen(FlashcardProvider flashcardProvider) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Debug information
        print('DEBUG: QuizProvider state - isLoading: ${quizProvider.isLoading}, attempts: ${quizProvider.attemptsCount}');
        print('DEBUG: Auth state - isPremium: ${authProvider.isPremium}, user: ${authProvider.currentUser?.uid}');
        
        // Show loading indicator if quiz attempts are still loading
        if (quizProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading quiz data...'),
              ],
            ),
          );
        }
        
        final availableFlashcards = flashcardProvider.flashcards.length;
        final maxQuestions = availableFlashcards > 10 ? 10 : availableFlashcards;
        
        // Check premium status and quiz attempts
        final isPremium = authProvider.isPremium;
        final attemptsCount = quizProvider.attemptsCount;
        final canTakeQuiz = isPremium || attemptsCount < 3;
        
        print('DEBUG: Quiz gating - isPremium: $isPremium, attempts: $attemptsCount, canTakeQuiz: $canTakeQuiz');
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // DEBUG INFO - Remove this in production
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEBUG: attempts=$attemptsCount, premium=$isPremium, canTake=$canTakeQuiz',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.quiz,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ready for a Quiz?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Test your knowledge with flashcards',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.flip,
                      'Available Flashcards',
                      '$availableFlashcards',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.quiz,
                      'Quiz Questions',
                      '$maxQuestions',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.timer,
                      'Time Limit',
                      'No limit',
                    ),
                    if (!isPremium) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.lock,
                        'Quiz Attempts',
                        '$attemptsCount/3',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (canTakeQuiz) ...[
                CustomButton(
                  text: 'Start Quiz',
                  onPressed: () => _startQuiz(),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quiz Limit Reached',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve reached the free quiz limit. Upgrade to Premium for unlimited quizzes!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Upgrade to Premium',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const PremiumUpgradeDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizQuestionScreen() {
    if (_currentQuiz == null || _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _currentQuiz!.questions[_currentQuestionIndex];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress Bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentQuestionIndex + 1) / _currentQuiz!.questions.length,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Question Counter
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_currentQuiz!.questions.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Answer Options
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isSelected = selectedAnswer == option;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _userAnswers[_currentQuestionIndex] = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.white : AppTheme.textLight,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation Buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: CustomButton(
                    text: 'Previous',
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
                    isOutlined: true,
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: _currentQuestionIndex == _currentQuiz!.questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next',
                  onPressed: () {
                    if (_currentQuestionIndex == _currentQuiz!.questions.length - 1) {
                      _completeQuiz();
                    } else {
                      setState(() {
                        _currentQuestionIndex++;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResultsScreen() {
    if (_currentQuiz == null) return const SizedBox.shrink();

    final totalQuestions = _currentQuiz!.questions.length;
    final correctAnswers = _currentQuiz!.questions.asMap().entries.where((entry) {
      final index = entry.key;
      final question = entry.value;
      final userAnswer = _userAnswers[index];
      return userAnswer == question.correctAnswer;
    }).length;

    final percentage = (correctAnswers / totalQuestions) * 100;
    final timeTaken = _quizStartTime != null 
        ? DateTime.now().difference(_quizStartTime!).inSeconds 
        : 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Result Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: percentage >= 70 
                  ? AppTheme.successColor.withOpacity(0.1)
                  : percentage >= 50
                      ? AppTheme.warningColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              percentage >= 70 
                  ? Icons.celebration
                  : percentage >= 50
                      ? Icons.sentiment_satisfied
                      : Icons.sentiment_dissatisfied,
              size: 60,
              color: percentage >= 70 
                  ? AppTheme.successColor
                  : percentage >= 50
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 32),

          // Score
          Text(
            '${correctAnswers}/${totalQuestions}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Performance Message
          Text(
            _getPerformanceMessage(percentage),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _getPerformanceDescription(percentage),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildResultRow('Correct Answers', '$correctAnswers', AppTheme.successColor),
                const SizedBox(height: 12),
                _buildResultRow('Incorrect Answers', '${totalQuestions - correctAnswers}', AppTheme.errorColor),
                const SizedBox(height: 12),
                _buildResultRow('Time Taken', '${timeTaken}s', AppTheme.primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Review Answers',
                  onPressed: () => _showAnswerReview(),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'New Quiz',
                  onPressed: () => _resetQuiz(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _startQuiz() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final quiz = quizProvider.generateQuizFromFlashcards(
        flashcardProvider.flashcards,
        authProvider.currentUser!.uid,
        'Quiz ${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() {
        _currentQuiz = quiz;
        _currentQuestionIndex = 0;
        _userAnswers.clear();
        _isQuizStarted = true;
        _isQuizCompleted = false;
        _quizStartTime = DateTime.now();
      });
    }
  }

  void _completeQuiz() {
    if (_currentQuiz == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final totalQuestions = _currentQuiz!.questions.length;
      final correctAnswers = _currentQuiz!.questions.asMap().entries.where((entry) {
        final index = entry.key;
        final question = entry.value;
        final userAnswer = _userAnswers[index];
        return userAnswer == question.correctAnswer;
      }).length;

      final timeTaken = _quizStartTime != null 
          ? DateTime.now().difference(_quizStartTime!).inSeconds 
          : 0;

      // Create quiz attempt
      final attempt = QuizAttempt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authProvider.currentUser!.uid,
        quizId: _currentQuiz!.id,
        score: correctAnswers,
        totalQuestions: totalQuestions,
        attemptedAt: DateTime.now(),
        timeTaken: timeTaken,
        answers: _currentQuiz!.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final userAnswer = _userAnswers[index] ?? '';
          return QuizAnswer(
            question: question.question,
            selectedAnswer: userAnswer,
            correctAnswer: question.correctAnswer,
            isCorrect: userAnswer == question.correctAnswer,
          );
        }).toList(),
      );

      // Save quiz attempt
      quizProvider.saveQuizAttempt(attempt);

      setState(() {
        _isQuizCompleted = true;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuiz = null;
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _isQuizStarted = false;
      _isQuizCompleted = false;
      _quizStartTime = null;
    });
  }

  void _showAnswerReview() {
    if (_currentQuiz == null) return;

    showDialog(
      context: context,
      builder: (context) => AnswerReviewDialog(
        quiz: _currentQuiz!,
        userAnswers: _userAnswers,
      ),
    );
  }

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 80) return 'Great Job!';
    if (percentage >= 70) return 'Good Work!';
    if (percentage >= 60) return 'Not Bad!';
    if (percentage >= 50) return 'Keep Trying!';
    return 'Need More Practice';
  }

  String _getPerformanceDescription(double percentage) {
    if (percentage >= 90) return 'Outstanding performance! You really know your stuff.';
    if (percentage >= 80) return 'Great work! You have a solid understanding.';
    if (percentage >= 70) return 'Good job! You\'re on the right track.';
    if (percentage >= 60) return 'Not bad! A bit more practice will help.';
    if (percentage >= 50) return 'Keep studying! Review the material again.';
    return 'Don\'t give up! Practice makes perfect.';
  }
}

class AnswerReviewDialog extends StatelessWidget {
  final QuizModel quiz;
  final Map<int, String> userAnswers;

  const AnswerReviewDialog({
    Key? key,
    required this.quiz,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Answer Review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final question = quiz.questions[index];
                  final userAnswer = userAnswers[index] ?? 'No answer';
                  final isCorrect = userAnswer == question.correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect 
                            ? AppTheme.successColor.withOpacity(0.3)
                            : AppTheme.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.question,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your answer: $userAnswer',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                        if (!isCorrect) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Correct answer: ${question.correctAnswer}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
} 