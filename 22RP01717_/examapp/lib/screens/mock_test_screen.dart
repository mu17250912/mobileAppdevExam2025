import 'package:flutter/material.dart';
import 'dart:math';
import '../questions_data.dart';
import '../services/progress_service.dart';
import '../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Added for jsonDecode

class MockTestScreen extends StatefulWidget {
  final String category;
  const MockTestScreen({required this.category});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  List<Map<String, dynamic>> questions = [];
  int current = 0;
  int? selected;
  int score = 0;
  bool showResult = false;
  final ProgressService progressService = ProgressService();
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = true;
  String? error;
  bool _showExplanationsSetting = true;
  String _difficultySetting = 'Any';
  int _testLengthSetting = 10;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndQuestions();
  }

  Future<void> _loadSettingsAndQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    _testLengthSetting = prefs.getInt('testLength') ?? 10;
    _showExplanationsSetting = prefs.getBool('showExplanations') ?? true;
    _difficultySetting = prefs.getString('difficulty') ?? 'Any';
    await _fetchMockQuestions();
  }

  Future<void> _fetchMockQuestions() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
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
      qs.shuffle();
      final limitedQs = qs.take(_testLengthSetting).toList();
      // If no questions, try offline fallback
      List<Map<String, dynamic>> finalQs = limitedQs;
      if (finalQs.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final allData = prefs.getString('offline_questions_all');
        if (allData != null) {
          final List<dynamic> allDecoded = jsonDecode(allData);
          var offlineQs = allDecoded.where((q) => (q['category']?.toString()?.toLowerCase() ?? '') == widget.category.toLowerCase()).map((e) => Map<String, dynamic>.from(e)).toList();
          if (_difficultySetting != 'Any') {
            offlineQs = offlineQs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
          }
          offlineQs.shuffle();
          finalQs = offlineQs.take(_testLengthSetting).toList();
        }
      }
      // FINAL OFFLINE FALLBACK: try local questionsData
      if (finalQs.isEmpty) {
        final localQs = questionsData.where((q) => (q['category']?.toString()?.toLowerCase() ?? '') == widget.category.toLowerCase()).toList();
        var filteredLocalQs = localQs;
        if (_difficultySetting != 'Any') {
          filteredLocalQs = localQs.where((q) => (q['difficulty'] ?? 'Any') == _difficultySetting).toList();
        }
        filteredLocalQs.shuffle();
        finalQs = filteredLocalQs.take(_testLengthSetting).toList();
      }
      setState(() {
        questions = finalQs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load questions.';
        isLoading = false;
      });
    }
  }

  void nextQuestion() async {
    if (selected == null) return;
    if (questions[current]['options'][selected!] == questions[current]['answer']) {
      score++;
    }
    if (current < questions.length - 1) {
      setState(() {
        current++;
        selected = null;
      });
    } else {
      await progressService.saveMockTestScore(widget.category, score);
      setState(() {
        showResult = true;
      });
    }
  }

  void restartTest() {
    setState(() {
      questions.shuffle();
      current = 0;
      selected = null;
      score = 0;
      showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Mock Test - ${widget.category}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mock Test - ${widget.category}')),
        body: Center(child: Text(error!)),
      );
    }
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Mock Test - ${widget.category}')),
        body: Center(child: Text('No questions found.')),
      );
    }
    if (showResult) {
      return Scaffold(
        appBar: AppBar(title: Text('Mock Test Result')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular score indicator
              Container(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: questions.isEmpty ? 0 : score / questions.length,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '$score / ${questions.length}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                score == questions.length
                    ? 'Excellent!'
                    : score >= (questions.length * 0.7)
                        ? 'Great job!'
                        : score >= (questions.length * 0.5)
                            ? 'Keep practicing!'
                            : 'Try again!',
                style: TextStyle(fontSize: 20, color: Colors.blueAccent, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: restartTest,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retake Test'),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: Text('Back to Categories'),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final pdf = pw.Document();
                  pdf.addPage(
                    pw.MultiPage(
                      build: (context) => [
                        pw.Header(level: 0, child: pw.Text('Mock Test - ${widget.category}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                        pw.Text('Score: $score / ${questions.length}\n'),
                        ...questions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final q = entry.value;
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Q${idx + 1}: ${q['question']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                              pw.Bullet(text: 'A) ${q['options'][0]}'),
                              pw.Bullet(text: 'B) ${q['options'][1]}'),
                              pw.Bullet(text: 'C) ${q['options'][2]}'),
                              pw.Bullet(text: 'D) ${q['options'][3]}'),
                              pw.Text('Correct Answer: ${q['answer']}', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                              if (_showExplanationsSetting && q['explanation'] != null && q['explanation'].toString().isNotEmpty)
                                pw.Text('Explanation: ${q['explanation']}', style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey)),
                              pw.SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: Text('Download as PDF'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[current];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mock Test - ${widget.category}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Question ${current + 1} of ${questions.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(q['question'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 24),
            ...List.generate(q['options'].length, (i) {
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  title: Text(q['options'][i], style: GoogleFonts.poppins(fontSize: 16)),
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: selected != null ? nextQuestion : null,
              child: Text(current == questions.length - 1 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
} 