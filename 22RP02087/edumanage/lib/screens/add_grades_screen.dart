import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddGradesScreen extends StatefulWidget {
  const AddGradesScreen({Key? key}) : super(key: key);

  @override
  State<AddGradesScreen> createState() => _AddGradesScreenState();
}

class _AddGradesScreenState extends State<AddGradesScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  String? _selectedStudentId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Grades'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').orderBy('studentId').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final students = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                  ),
                  items: students.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: data['studentId'],
                      child: Text(data['studentId'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                );
              },
            ),
            const SizedBox(height: 16),
            // Replace the course name TextField with a dropdown to choose course name:
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final courses = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _courseController.text.isNotEmpty && courses.any((c) => c['name'] == _courseController.text) ? _courseController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                  items: courses.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: data['name'],
                      child: Text(data['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _courseController.text = val ?? ''),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gradeController,
              decoration: InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _marksController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _semesterController,
              decoration: InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gpaController,
              decoration: InputDecoration(
                labelText: 'GPA Summary',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  final course = _courseController.text.trim();
                  final grade = _gradeController.text.trim();
                  final marks = _marksController.text.trim();
                  final semester = _semesterController.text.trim();
                  final gpa = _gpaController.text.trim();
                  final studentId = _selectedStudentId;
                  if (course.isEmpty || grade.isEmpty || marks.isEmpty || semester.isEmpty || gpa.isEmpty || studentId == null || studentId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields.')),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await FirebaseFirestore.instance.collection('grades').add({
                      'studentId': studentId,
                      'course': course,
                      'grade': grade,
                      'marks': marks,
                      'semester': semester,
                      'gpa': gpa,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    _courseController.clear();
                    _gradeController.clear();
                    _marksController.clear();
                    _semesterController.clear();
                    _gpaController.clear();
                    setState(() => _selectedStudentId = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grade added!')),
                    );
                    Navigator.pushReplacementNamed(context, '/admin_dashboard');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: \\${e.toString()}')),
                    );
                  }
                  setState(() => _isLoading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Grade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 