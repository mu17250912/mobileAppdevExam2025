import 'dart:math';
import 'package:flutter/material.dart';
import '../data/quiz_data.dart';

class SkillQuizPage extends StatefulWidget {
  const SkillQuizPage({Key? key}) : super(key: key);

  @override
  State<SkillQuizPage> createState() => _SkillQuizPageState();
}

class _SkillQuizPageState extends State<SkillQuizPage> {
  late List<QuizQuestion> _quizQuestions;
  int _currentQuestion = 0;
  List<int?> _selectedAnswers = List.filled(10, null);
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _generateRandomQuiz();
  }

  void _generateRandomQuiz() {
    final random = Random();
    final pool = List<QuizQuestion>.from(skillQuizQuestionsPool);
    pool.shuffle(random);
    _quizQuestions = pool.take(10).toList();
    _selectedAnswers = List.filled(_quizQuestions.length, null);
    _currentQuestion = 0;
    _showResult = false;
  }

  int get _score {
    int score = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      if (_selectedAnswers[i] == _quizQuestions[i].correctIndex) {
        score++;
      }
    }
    return score;
  }

  void _next() {
    if (_currentQuestion < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      setState(() {
        _showResult = true;
      });
    }
  }

  void _restart() {
    setState(() {
      _generateRandomQuiz();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Skill Assessment Result'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Score: $_score / ${_quizQuestions.length}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Review your answers:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...List.generate(_quizQuestions.length, (i) {
                  final q = _quizQuestions[i];
                  final userAnswer = _selectedAnswers[i];
                  final isCorrect = userAnswer == q.correctIndex;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q${i + 1}: ${q.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Your answer: ' + (userAnswer != null ? q.options[userAnswer] : 'No answer'),
                            style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
                          ),
                          if (!isCorrect)
                            Text('Correct answer: ${q.options[q.correctIndex]}', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _restart,
                  child: const Text('Restart Quiz'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _quizQuestions[_currentQuestion];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Assessment Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentQuestion + 1} of ${_quizQuestions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedAnswers[_currentQuestion],
                onChanged: (value) {
                  setState(() {
                    _selectedAnswers[_currentQuestion] = value;
                  });
                },
                title: Text(question.options[index]),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestion > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestion--;
                      });
                    },
                    child: const Text('Back'),
                  ),
                ElevatedButton(
                  onPressed: _selectedAnswers[_currentQuestion] != null ? _next : null,
                  child: Text(_currentQuestion == _quizQuestions.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 