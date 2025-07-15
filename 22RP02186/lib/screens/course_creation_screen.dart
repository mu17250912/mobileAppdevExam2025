import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseCreationScreen extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? courseToEdit;
  
  const CourseCreationScreen({Key? key, required this.userEmail, this.courseToEdit}) : super(key: key);

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  List<Map<String, dynamic>> lessons = [];
  bool isPremium = false;
  double price = 0.0;
  bool isLoading = false;
  String? editingCourseId;
  bool jobReady = false;

  final List<String> categories = [
    'Computer Skills',
    'Cooking',
    'Digital Skills',
    'Health & Fitness',
    'Language Learning',
    'Music',
    'Photography',
    'Programming',
    'Tailoring',
    'Communication',
    'Other',
  ];

  final List<String> levels = [
    'Beginner',
    'Intermediate',
    'Advanced'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.courseToEdit != null) {
      final c = widget.courseToEdit!;
      editingCourseId = c['id']?.toString();
      _titleController.text = c['title'] ?? '';
      _descriptionController.text = c['description'] ?? '';
      _categoryController.text = c['category'] ?? '';
      _levelController.text = c['level'] ?? '';
      _durationController.text = c['duration'] ?? '';
      lessons = List<Map<String, dynamic>>.from(c['lessons'] ?? []);
      isPremium = c['isPremium'] ?? false;
      price = (c['price'] is num) ? c['price'].toDouble() : 0.0;
      jobReady = c['jobReady'] ?? false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _levelController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addLesson() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController videoURLController = TextEditingController();
    final TextEditingController durationController = TextEditingController(text: '10 min');
    bool isPremiumLesson = false;
    List<String> subtopics = [];

    void addSubtopic(String subtopic) {
      if (subtopic.trim().isNotEmpty) {
        subtopics.add(subtopic.trim());
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Lesson', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Lesson Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: videoURLController,
                  decoration: InputDecoration(
                    labelText: 'Video URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (e.g., 10 min)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isPremiumLesson,
                      onChanged: (value) {
                        setState(() {
                          isPremiumLesson = value ?? false;
                        });
                      },
                    ),
                    Text('Premium Lesson'),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Add Subtopic',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (subtopic) {
                          setState(() {
                            addSubtopic(subtopic);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (subtopics.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subtopics.map((s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('- $s'),
                    )).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                // Prevent duplicate lesson titles
                if (lessons.any((l) => (l['title'] ?? '').toString().toLowerCase() == title.toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('A lesson with this title already exists.')),
                  );
                  return;
                }
                setState(() {
                  lessons.add({
                    'title': title,
                    'content': contentController.text.trim(),
                    'videoURL': videoURLController.text.trim(),
                    'isPremium': isPremiumLesson,
                    'duration': durationController.text.trim(),
                    'subtopics': List<String>.from(subtopics),
                  });
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editLesson(int index) {
    final lesson = lessons[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Lesson', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Lesson Title'),
                controller: TextEditingController(text: lesson['title']),
                onChanged: (value) => lesson['title'] = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Content Description'),
                controller: TextEditingController(text: lesson['content']),
                maxLines: 3,
                onChanged: (value) => lesson['content'] = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Video URL'),
                controller: TextEditingController(text: lesson['videoURL']),
                onChanged: (value) => lesson['videoURL'] = value,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: lesson['isPremium'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        lesson['isPremium'] = value;
                      });
                    },
                  ),
                  Text('Premium Lesson'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSubtopic(int lessonIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subtopic', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(labelText: 'Subtopic Title'),
          onSubmitted: (subtopic) {
            if (subtopic.isNotEmpty) {
              setState(() {
                lessons[lessonIndex]['subtopics'].add(subtopic);
              });
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one lesson')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'level': _levelController.text,
        'duration': _durationController.text,
        'trainerEmail': widget.userEmail,
        'trainerName': 'Trainer Name', // You can get this from user profile
        'lessons': lessons,
        'isPremium': isPremium,
        'price': price,
        'enrolledStudents': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'jobReady': jobReady,
      };
      if (editingCourseId != null) {
        // Show confirmation dialog before updating
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Update Course'),
            content: Text('Are you sure you want to save changes to this course?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Save'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          setState(() { isLoading = false; });
          return;
        }
        // Update existing course
        await FirebaseFirestore.instance.collection('courses').doc(editingCourseId).update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course updated successfully!')),
        );
      } else {
        // Create new course
        await FirebaseFirestore.instance.collection('courses').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course created successfully!')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving course: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          editingCourseId != null ? 'Edit Course' : 'Create New Course',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: _saveCourse,
              child: Text(
                'Save Course',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildPremiumSettings(),
                    const SizedBox(height: 24),
                    _buildLessonsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Course Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Course Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _categoryController.text.isEmpty ? null : _categoryController.text,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                    ),
                    value: _levelController.text.isEmpty ? null : _levelController.text,
                    items: levels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _levelController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a level';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Estimated Duration (e.g., 2 hours)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter estimated duration';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: jobReady,
                  onChanged: (value) {
                    setState(() {
                      jobReady = value ?? false;
                    });
                  },
                ),
                Text('Job Ready (auto-generate job for this course)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Settings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: isPremium,
                  onChanged: (value) {
                    setState(() {
                      isPremium = value ?? false;
                      if (!isPremium) price = 0.0;
                    });
                  },
                ),
                Text('Make this a premium course'),
              ],
            ),
            if (isPremium) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    price = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course Lessons',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addLesson,
                  icon: Icon(Icons.add),
                  label: Text('Add Lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lessons.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No lessons added yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first lesson to get started',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(
                        lesson['title'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        (lesson['isPremium'] ?? false) ? 'Premium Lesson' : 'Free Lesson',
                        style: GoogleFonts.poppins(
                          color: (lesson['isPremium'] ?? false) ? Colors.orange : Colors.green,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editLesson(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Lesson'),
                                  content: Text('Are you sure you want to delete this lesson?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setState(() {
                                  lessons.removeAt(index);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((lesson['content'] ?? '').isNotEmpty)
                                Text(
                                  'Content: ${lesson['content']}',
                                  style: GoogleFonts.poppins(),
                                ),
                              if ((lesson['videoURL'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Video: ${lesson['videoURL']}',
                                  style: GoogleFonts.poppins(color: Colors.blue),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtopics',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _addSubtopic(index),
                                    icon: Icon(Icons.add, size: 16),
                                    label: Text('Add'),
                                  ),
                                ],
                              ),
                              if ((lesson['subtopics'] ?? []).isNotEmpty)
                                ...(lesson['subtopics'] as List<dynamic>).map<Widget>((subtopic) => Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_right, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(subtopic)),
                                    ],
                                  ),
                                )).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
} 