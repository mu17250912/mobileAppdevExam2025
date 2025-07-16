import 'package:flutter/material.dart';
import '../questions_data.dart';
import '../services/progress_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class QuestionScreen extends StatefulWidget {
  final String category;
  final int? numQuestions;
  final List<Map<String, dynamic>>? questions;
  const QuestionScreen({required this.category, this.numQuestions, this.questions});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int current = 0;
  int? selected;
  bool showExplanation = false;
  List<int> flagged = [];
  List<int?> userAnswers = [];
  final ProgressService progressService = ProgressService();
  Map<String, dynamic> progress = {};

  List<Map<String, dynamic>> _questions = [];
  bool _loadingQuestions = true;
  bool _showExplanationsSetting = true;
  String _difficultySetting = 'Any';
  int _testLengthSetting = 10;

  @override
  void initState() {
    super.initState();
    if (widget.questions != null) {
      _questions = widget.questions!;
      _loadingQuestions = false;
    } else {
      _loadSettingsAndData();
    }
  }

  Future<void> _loadSettingsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _testLengthSetting = prefs.getInt('testLength') ?? 10;
    _showExplanationsSetting = prefs.getBool('showExplanations') ?? true;
    _difficultySetting = prefs.getString('difficulty') ?? 'Any';
    await _loadProgress();
    await _loadQuestions();
  }

  Future<void> _loadProgress() async {
    progress = await progressService.loadProgress();
    setState(() {});
  }

  Future<void> _updateProgress(bool correct) async {
    final cat = widget.category.toLowerCase();
    if (!progress.containsKey(cat)) {
      progress[cat] = {'attempted': 0, 'correct': 0};
    }
    progress[cat]['attempted'] += 1;
    if (correct) progress[cat]['correct'] += 1;
    await progressService.saveProgress(progress);
    setState(() {});
  }

  Future<void> _loadQuestions() async {
    List<String> variants = [widget.category];
    final cat = widget.category.toLowerCase();
    if (["physics", "phyisics", "PHYSICS"].contains(cat)) {
      variants = ["physics", "Physics", "Phyisics", "PHYSICS"];
    }
    if (cat == "math" || cat == "mathematics") {
      variants = ["math", "Math", "mathematics"];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('questions')
        .where('category', whereIn: variants)
        .get();
    var qs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    // Filter by difficulty if set
    if (_difficultySetting != 'Any') {
      qs = qs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
    }
    // Fallback to local if Firestore is empty
    if (qs.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('offline_questions_${widget.category.toLowerCase()}');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        qs = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        if (_difficultySetting != 'Any') {
          qs = qs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
        }
      } else {
        qs = questionsData.where((q) => q['category'].toString().toLowerCase() == widget.category.toLowerCase()).toList();
        if (_difficultySetting != 'Any') {
          qs = qs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
        }
        // FINAL OFFLINE FALLBACK: try all offline questions
        if (qs.isEmpty) {
          final allData = prefs.getString('offline_questions_all');
          if (allData != null) {
            final List<dynamic> allDecoded = jsonDecode(allData);
            qs = allDecoded.where((q) => (q['category']?.toString()?.toLowerCase() ?? '') == widget.category.toLowerCase()).map((e) => Map<String, dynamic>.from(e)).toList();
            if (_difficultySetting != 'Any') {
              qs = qs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
            }
          }
        }
      }
    }
    if (_testLengthSetting < qs.length) {
      qs.shuffle();
      qs = qs.take(_testLengthSetting).toList();
    }
    _questions = qs;
    setState(() {
      _loadingQuestions = false;
    });
  }

  void nextQuestion(int total) {
    setState(() {
      userAnswers.length <= current ? userAnswers.add(selected) : userAnswers[current] = selected;
      current = (current + 1) % total;
      selected = null;
      showExplanation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            tooltip: 'Review Flagged',
            onPressed: () {
              if (flagged.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No flagged questions.')),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Flagged Questions'),
                    content: SizedBox(
                      width: 350,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: flagged.length,
                        itemBuilder: (context, i) {
                          final idx = flagged[i];
                          final fq = _questions[idx];
                          return ListTile(
                            title: Text(fq['question'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              tooltip: 'Unflag',
                              onPressed: () {
                                setState(() {
                                  flagged.remove(idx);
                                });
                                Navigator.pop(context);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                current = idx;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(flagged.contains(current) ? Icons.flag : Icons.outlined_flag),
            tooltip: flagged.contains(current) ? 'Unflag' : 'Flag',
            onPressed: () async {
              setState(() {
                if (flagged.contains(current)) {
                  flagged.remove(current);
                } else {
                  flagged.add(current);
                }
              });
              // Sync to Firestore if user is logged in
              if (user != null) {
                final flaggedQuestions = flagged.map((idx) => _questions[idx]['question'] as String).toList();
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'flaggedQuestions': flaggedQuestions});
              }
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loadingQuestions) return Center(child: CircularProgressIndicator());
          if (_questions.isEmpty) return Center(child: Text('No questions found.'));
          final q = _questions[current];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: (current + 1) / _questions.length,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                  minHeight: 8,
                ),
                SizedBox(height: 24),
                // Question card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(q['question'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
                // Options
                ...List.generate((q['options'] as List).length, (i) {
                  final isSelected = selected == i;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(q['options'][i], style: TextStyle(fontSize: 16)),
                      leading: Radio<int>(
                        value: i,
                        groupValue: selected,
                        onChanged: (val) {
                          setState(() {
                            selected = val;
                          });
                        },
                      ),
                    ),
                  );
                }),
                if (_showExplanationsSetting && showExplanation && selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(q['explanation'] ?? '', style: TextStyle(color: Colors.blue)),
                  ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    userAnswers.length <= current ? userAnswers.add(selected) : userAnswers[current] = selected;
                    if (current < _questions.length - 1) {
                      nextQuestion(_questions.length);
                    } else {
                      // Calculate session results
                      int attempted = userAnswers.where((a) => a != null).length;
                      int correct = 0;
                      for (int i = 0; i < _questions.length; i++) {
                        final q = _questions[i];
                        final userAns = userAnswers.length > i ? userAnswers[i] : null;
                        final correctAns = (q['options'] as List).indexOf(q['answer']);
                        if (userAns == correctAns) correct++;
                      }
                      // Load and update progress
                      final cat = widget.category.toLowerCase();
                      Map<String, dynamic> prog = await progressService.loadProgress();
                      if (!prog.containsKey(cat)) {
                        prog[cat] = {'attempted': 0, 'correct': 0};
                      }
                      prog[cat]['attempted'] += attempted;
                      prog[cat]['correct'] += correct;
                      await progressService.saveProgress(prog);
                      // Show review/summary dialog
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Practice Complete'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('You have completed your practice session!'),
                                  SizedBox(height: 16),
                                  ...List.generate(_questions.length, (i) {
                                    final q = _questions[i];
                                    final userAns = userAnswers.length > i ? userAnswers[i] : null;
                                    final correctAns = (q['options'] as List).indexOf(q['answer']);
                                    final isCorrect = userAns == correctAns;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Q${i + 1}: ${q['question']}', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Your answer: ${userAns != null ? q['options'][userAns] : 'No answer'}', style: TextStyle(color: isCorrect ? Colors.green : Colors.red)),
                                          Text('Correct answer: ${q['answer']}', style: TextStyle(color: Colors.green)),
                                          if (_showExplanationsSetting && q['explanation'] != null)
                                            Text('Explanation: ${q['explanation']}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                                        ],
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 16),
                                  Text('Score: $correct / ${_questions.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(current < _questions.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 