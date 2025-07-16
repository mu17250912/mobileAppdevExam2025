import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../questions_data.dart';
import 'manage_category_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

enum AdminSection {
  dashboard,
  flaggedQuestions,
  userManagement,
  contentModeration,
  appConfig,
  analytics,
  manageCategories,
  trainers, // Add this
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  AdminSection _selectedSection = AdminSection.dashboard;
  String? selectedCategory;
  List<String> categories = [];
  bool loadingCategories = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() { loadingCategories = true; });
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    categories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    if (categories.isNotEmpty) selectedCategory = categories.first;
    if (!mounted) return;
    setState(() { loadingCategories = false; });
  }

  Stream<QuerySnapshot> getQuestionsStream() {
    if (selectedCategory != null) {
      final cat = selectedCategory!.toLowerCase();
      List<String> variants = [cat];
      if (['physics', 'phyisics', 'PHYSICS'].contains(cat)) {
        variants = ['physics', 'Physics', 'Phyisics', 'PHYSICS'];
      }
      if (cat == 'math') variants = ['math', 'Math', 'mathematics'];
      if (cat == 'english') variants = ['english', 'English'];
      if (cat == 'biology') variants = ['biology', 'Biology'];
      if (cat == 'chemistry') variants = ['chemistry', 'Chemistry'];
      if (cat == 'history') variants = ['history', 'History'];
      if (cat == 'geography') variants = ['geography', 'Geography'];
      return FirebaseFirestore.instance
          .collection('questions')
          .where('category', whereIn: variants)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('questions')
        .snapshots();
  }

  Future<void> showQuestionDialog({DocumentSnapshot? doc}) async {
    final isEdit = doc != null;
    final data = isEdit ? doc.data() as Map<String, dynamic> : {};
    final questionController = TextEditingController(text: data['question'] ?? '');
    final explanationController = TextEditingController(text: data['explanation'] ?? '');
    final optionControllers = List.generate(4, (i) => TextEditingController(text: (data['options'] != null && data['options'].length > i) ? data['options'][i] : ''));
    String answer = isEdit ? (data['answer'] ?? '') : '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(isEdit ? 'Edit Question' : 'Add Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(labelText: 'Question'),
                  ),
                  SizedBox(height: 8),
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: optionControllers[i],
                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                      onChanged: (_) => setState(() {}), // Update dropdown options
                    ),
                  )),
                  DropdownButtonFormField<String>(
                    value: answer.isNotEmpty ? answer : null,
                    items: optionControllers
                        .map((c) => c.text)
                        .where((t) => t.isNotEmpty)
                        .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                        .toList(),
                    onChanged: (val) => setState(() => answer = val ?? ''),
                    decoration: InputDecoration(labelText: 'Correct Answer'),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(labelText: 'Explanation'),
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
                onPressed: () async {
                  final options = optionControllers.map((c) => c.text).toList();
                  if (questionController.text.isEmpty || options.any((o) => o.isEmpty) || answer.isEmpty) return;
                  final qData = {
                    'category': selectedCategory,
                    'question': questionController.text,
                    'options': options,
                    'answer': answer,
                    'explanation': explanationController.text,
                  };
                  if (isEdit) {
                    await doc!.reference.update(qData);
                  } else {
                    await FirebaseFirestore.instance.collection('questions').add(qData);
                  }
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedSection.index,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedSection = AdminSection.values[index];
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.flag),
                label: Text('Flagged'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified),
                label: Text('Moderation'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Config'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Manage Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fitness_center),
                label: Text('Trainers'),
              ),
            ],
          ),
          VerticalDivider(width: 1),
          Expanded(
            child: _buildSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_selectedSection) {
      case AdminSection.dashboard:
        return _buildDashboardHome();
      case AdminSection.flaggedQuestions:
        return _buildFlaggedQuestionsSection();
      case AdminSection.userManagement:
        return _buildUserManagementSection();
      case AdminSection.contentModeration:
        return _buildContentModerationSection();
      case AdminSection.appConfig:
        return _buildAppConfigSection();
      case AdminSection.analytics:
        return _buildAnalyticsSection();
      case AdminSection.manageCategories:
        return ManageCategoryScreen();
      case AdminSection.trainers:
        return _buildTrainerManagementSection();
    }
  }

  Widget _buildDashboardHome() {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: loadingCategories
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat[0].toUpperCase() + cat.substring(1)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    // CATEGORY MANAGEMENT SECTION
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Category'),
                            onPressed: () async {
                              final name = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: Text('Add Category'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(labelText: 'Category Name'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                                        child: Text('Add'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (name != null && name.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('categories').add({'name': name});
                                fetchCategories();
                              }
                            },
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.cloud_upload),
                            label: Text('Upload All Questions to Database'),
                            onPressed: () async {
                              int success = 0;
                              int fail = 0;
                              for (final q in questionsData) {
                                try {
                                  await FirebaseFirestore.instance.collection('questions').add(q);
                                  success++;
                                } catch (e) {
                                  fail++;
                                }
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Uploaded: '
                                      ' [32m$success [0m, Failed: '
                                      ' [31m$fail [0m'),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Question'),
                            onPressed: () => showQuestionDialog(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Questions section
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Question'),
                            onPressed: () => showQuestionDialog(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        minHeight: 200,
                        maxHeight: 400,
                      ),
                      child: selectedCategory == null
                          ? Center(child: Text('Select a category'))
                          : StreamBuilder<QuerySnapshot>(
                              stream: getQuestionsStream(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) return Center(child: Text('No questions for this category.'));
                                return ListView.builder(
                                  padding: EdgeInsets.only(bottom: 16),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final q = docs[index].data() as Map<String, dynamic>;
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        title: Text(q['question'] ?? ''),
                                        subtitle: Text('Answer: ${q['answer'] ?? ''}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () => showQuestionDialog(doc: docs[index]),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () async {
                                                await docs[index].reference.delete();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFlaggedQuestionsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator());
        final users = userSnapshot.data!.docs;
        // Collect all flagged question IDs
        final flaggedMap = <String, List<String>>{};
        for (final user in users) {
          final data = user.data() as Map<String, dynamic>;
          final flagged = data.containsKey('flaggedQuestions') ? List<String>.from(data['flaggedQuestions'] ?? []) : <String>[];
          if (flagged.isNotEmpty) {
            flaggedMap[user.id] = flagged;
          }
        }
        final allFlaggedIds = flaggedMap.values.expand((x) => x).toSet().toList();
        if (allFlaggedIds.isEmpty) {
          return Center(child: Text('No flagged questions by any user.'));
        }
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('questions').where('question', whereIn: allFlaggedIds).get(),
          builder: (context, qSnapshot) {
            if (!qSnapshot.hasData) return Center(child: CircularProgressIndicator());
            final questions = qSnapshot.data!.docs;
            if (questions.isEmpty) return Center(child: Text('No flagged questions found in database.'));
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: questions.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final q = questions[index].data() as Map<String, dynamic>;
                final qId = q['question'];
                // Find users who flagged this question
                final flaggedBy = users.where((u) {
                  final data = u.data() as Map<String, dynamic>;
                  return data.containsKey('flaggedQuestions') && (data['flaggedQuestions'] ?? []).contains(qId);
                }).toList();
                return Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(q['question'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Question',
                              onPressed: () async {
                                await questions[index].reference.delete();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (q['explanation'] != null)
                          Text('Explanation: ${q['explanation']}', style: TextStyle(color: Colors.blueGrey)),
                        SizedBox(height: 10),
                        Text('Flagged by:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...flaggedBy.map((u) => Text(u['email'] ?? u.id)),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.edit),
                              label: Text('Edit'),
                              onPressed: () {
                                // Optionally implement edit dialog
                              },
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.check),
                              label: Text('Mark Resolved'),
                              onPressed: () async {
                                // Remove this question from all users' flaggedQuestions
                                for (final u in flaggedBy) {
                                  final List<String> flagged = List<String>.from(u['flaggedQuestions'] ?? []);
                                  flagged.remove(qId);
                                  await FirebaseFirestore.instance.collection('users').doc(u.id).update({'flaggedQuestions': flagged});
                                }
                                if (!mounted) return;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserManagementSection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator());
        // Filter out admin users
        final users = userSnapshot.data!.docs.where((u) => (u['userType'] ?? 'normal') != 'admin').toList();
        if (users.isEmpty) return Center(child: Text('No users found.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final user = users[index];
            final email = user['email'] ?? user.id;
            final userType = user['userType'] ?? 'normal';
            return Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(email, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Type: $userType'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userType != 'premium')
                      ElevatedButton(
                        child: Text('Upgrade to Premium'),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('users').doc(user.id).update({'userType': 'premium'});
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      child: Text('View Progress'),
                      onPressed: () async {
                        // Show user progress in a dialog
                        final progressDoc = await FirebaseFirestore.instance.collection('progress').doc(user.id).get();
                        final progress = progressDoc.data() ?? {};
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Progress for $email'),
                            content: progress.isEmpty
                                ? Text('No progress data.')
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: progress.entries.map<Widget>((e) => Text('${e.key}: Attempted ${e.value['attempted']}, Correct ${e.value['correct']}')).toList(),
                                  ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
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
          },
        );
      },
    );
  }

  Widget _buildContentModerationSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Submissions'),
              Tab(text: 'Reports'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // User-submitted questions
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('pending_questions').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No user-submitted questions.'));
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final q = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(q['question'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Category: ${q['category'] ?? ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Approve',
                                  onPressed: () async {
                                    // Move to questions collection
                                    await FirebaseFirestore.instance.collection('questions').add(q);
                                    await docs[index].reference.delete();
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Reject',
                                  onPressed: () async {
                                    await docs[index].reference.delete();
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Reports
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('reports').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No reports.'));
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final r = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text('Report: ${r['reason'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Question: ${r['question'] ?? ''}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Report',
                              onPressed: () async {
                                await docs[index].reference.delete();
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppConfigSection() {
    final announcementController = TextEditingController();
    bool enableMockTest = true;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('app_config').doc('main').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          announcementController.text = data['announcement'] ?? '';
          enableMockTest = data['enableMockTest'] ?? true;
        }
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Announcement Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              TextField(
                controller: announcementController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter announcement for all users',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Text('Enable Mock Test', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: enableMockTest,
                    onChanged: (val) async {
                      await FirebaseFirestore.instance.collection('app_config').doc('main').set({
                        'enableMockTest': val,
                        'announcement': announcementController.text,
                      }, SetOptions(merge: true));
                      // Force rebuild
                      setState(() {});
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                child: Text('Save Configuration'),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('app_config').doc('main').set({
                    'announcement': announcementController.text,
                    'enableMockTest': enableMockTest,
                  }, SetOptions(merge: true));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Configuration saved!')));
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsSection() {
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('questions').get(),
        FirebaseFirestore.instance.collection('categories').get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return Center(child: Text('No analytics data.'));
        final results = snapshot.data as List;
        final users = results[0].docs;
        final questions = results[1].docs;
        final categories = results[2].docs;
        // Count questions per category
        final Map<String, int> categoryCounts = {};
        for (final cat in categories) {
          final name = cat['name'] ?? 'Unknown';
          categoryCounts[name] = 0;
        }
        for (final q in questions) {
          final cat = q['category'] ?? 'Unknown';
          if (categoryCounts.containsKey(cat)) {
            categoryCounts[cat] = categoryCounts[cat]! + 1;
          } else {
            categoryCounts[cat] = 1;
          }
        }
        final sortedCategories = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _analyticsCard('Total Users', users.length.toString(), Icons.people),
                      SizedBox(width: 32),
                      _analyticsCard('Total Questions', questions.length.toString(), Icons.help),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Text('Most Popular Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 12),
                ...sortedCategories.take(5).map((e) => ListTile(
                  leading: Icon(Icons.category),
                  title: Text(e.key),
                  trailing: Text('${e.value} questions'),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _analyticsCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.indigo),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(value, style: TextStyle(fontSize: 22)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerManagementSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trainers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trainers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Trainer'),
                    onPressed: () async {
                      final nameController = TextEditingController();
                      final emailController = TextEditingController();
                      final passwordController = TextEditingController(text: '12345678');
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Add Trainer'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'After adding a trainer, please register this email via the app\'s Register screen to enable login.',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(labelText: 'Name'),
                              ),
                              TextField(
                                controller: emailController,
                                decoration: InputDecoration(labelText: 'Email'),
                              ),
                              TextField(
                                controller: passwordController,
                                decoration: InputDecoration(labelText: 'Password'),
                                obscureText: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();
                                if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
                                  try {
                                    // Create user in Firebase Auth
                                    UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                      email: email,
                                      password: password,
                                    );
                                    final uid = cred.user?.uid;
                                    // Add to trainers collection
                                    await FirebaseFirestore.instance.collection('trainers').add({
                                      'name': name,
                                      'email': email,
                                      'password': password,
                                    });
                                    // Add to users collection with userType: trainer
                                    await FirebaseFirestore.instance.collection('users').doc(uid).set({
                                      'displayName': name,
                                      'email': email,
                                      'userType': 'trainer',
                                      'avatarUrl': '',
                                      'flaggedQuestions': [],
                                      'hasShared': false,
                                      'sharedPlatforms': {},
                                    });
                                    Navigator.pop(context);
                                  } catch (e) {
                                    String msg = 'Error: ' + (e is FirebaseAuthException ? e.message ?? e.code : e.toString());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }
                                }
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trainer = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(trainer['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(trainer['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.indigo),
                              onPressed: () async {
                                final nameController = TextEditingController(text: trainer['name'] ?? '');
                                final emailController = TextEditingController(text: trainer['email'] ?? '');
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Edit Trainer'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(labelText: 'Name'),
                                        ),
                                        TextField(
                                          controller: emailController,
                                          decoration: InputDecoration(labelText: 'Email'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                                            await docs[index].reference.update({
                                              'name': nameController.text.trim(),
                                              'email': emailController.text.trim(),
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await docs[index].reference.delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 