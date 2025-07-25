import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignQuestionsScreen extends StatefulWidget {
  @override
  _AssignQuestionsScreenState createState() => _AssignQuestionsScreenState();
}

class _AssignQuestionsScreenState extends State<AssignQuestionsScreen> {
  String? selectedCategory;
  List<String> categories = [];
  List<Map<String, dynamic>> questions = [];
  Set<String> selectedQuestionIds = {};
  String? selectedUserId;
  List<Map<String, dynamic>> users = [];
  bool loadingCategories = true;
  bool loadingQuestions = false;
  bool loadingUsers = true;
  bool assigning = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchUsers();
  }

  Future<void> fetchCategories() async {
    setState(() { loadingCategories = true; });
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    categories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    if (categories.isNotEmpty) selectedCategory = categories.first;
    setState(() { loadingCategories = false; });
    if (selectedCategory != null) fetchQuestions(selectedCategory!);
  }

  Future<void> fetchQuestions(String category) async {
    setState(() { loadingQuestions = true; });
    List<String> variants = [category];
    final cat = category.toLowerCase();
    if (["physics", "phyisics", "PHYSICS"].contains(cat)) {
      variants = ["physics", "Physics", "Phyisics", "PHYSICS"];
    }
    if (cat == "math" || cat == "mathematics") {
      variants = ["math", "Math", "mathematics"];
    }
    if (cat == "english") {
      variants = ["english", "English"];
    }
    if (cat == "biology") {
      variants = ["biology", "Biology"];
    }
    if (cat == "chemistry") {
      variants = ["chemistry", "Chemistry"];
    }
    if (cat == "history") {
      variants = ["history", "History"];
    }
    if (cat == "geography") {
      variants = ["geography", "Geography"];
    }
    if (cat == "literature") {
      variants = ["literature", "Literature"];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('questions')
        .where('category', whereIn: variants)
        .get();
    questions = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    print('Fetched ${questions.length} questions for category: $category');
    setState(() { loadingQuestions = false; });
  }

  Future<void> fetchUsers() async {
    setState(() { loadingUsers = true; });
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    users = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).where((u) => u['userType'] != 'admin' && u['userType'] != 'trainer').toList();
    setState(() { loadingUsers = false; });
  }

  Future<void> assignQuestions() async {
    if (selectedUserId == null || selectedQuestionIds.isEmpty) return;
    setState(() { assigning = true; });
    await FirebaseFirestore.instance.collection('users').doc(selectedUserId).set({
      'assignedQuestions': selectedQuestionIds.toList(),
    }, SetOptions(merge: true));
    setState(() { assigning = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Questions assigned successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Questions to User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Category:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (loadingCategories)
              CircularProgressIndicator()
            else
              DropdownButton<String>(
                value: selectedCategory,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  setState(() { selectedCategory = val; });
                  if (val != null) fetchQuestions(val);
                },
              ),
            SizedBox(height: 16),
            Text('Select Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (loadingQuestions)
              CircularProgressIndicator()
            else if (questions.isEmpty)
              Text('No questions found for this category.', style: TextStyle(color: Colors.red))
            else
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: questions.map((q) {
                    return CheckboxListTile(
                      value: selectedQuestionIds.contains(q['id']),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedQuestionIds.add(q['id']);
                          } else {
                            selectedQuestionIds.remove(q['id']);
                          }
                        });
                      },
                      title: Text(q['question'] ?? ''),
                      subtitle: Text((q['options'] as List).join(', ')),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 16),
            Text('Select User:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (loadingUsers)
              CircularProgressIndicator()
            else
              DropdownButton<String>(
                value: selectedUserId,
                items: users.map((u) => DropdownMenuItem<String>(
                  value: u['id'] as String,
                  child: Text((u['email'] ?? u['id']).toString()),
                )).toList(),
                onChanged: (val) {
                  setState(() { selectedUserId = val; });
                },
              ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: assigning ? null : assignQuestions,
                icon: Icon(Icons.assignment_turned_in),
                label: assigning ? Text('Assigning...') : Text('Assign Selected Questions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 