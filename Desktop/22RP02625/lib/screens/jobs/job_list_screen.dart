import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? _statusFilter;
  String? _categoryFilter;
  String? _locationFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> _categories = ['Plumbing', 'Electrical', 'Cleaning', 'Other'];
  List<String> _locations = ['Kigali', 'Musanze', 'Huye', 'Other'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('jobs');
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      query = query.where('status', isEqualTo: _statusFilter);
    }
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      query = query.where('category', isEqualTo: _categoryFilter);
    }
    if (_locationFilter != null && _locationFilter!.isNotEmpty) {
      query = query.where('location', isEqualTo: _locationFilter);
    }
    return query.orderBy('createdAt', descending: true);
  }

  Future<void> _applyForJob(String jobId, List applicants, {String? status}) async {
    if (user == null) return;
    if (applicants.contains(user!.uid)) return;
    if (status == 'Closed') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applications are closed for this job.')));
      return;
    }
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'applicants': FieldValue.arrayUnion([user!.uid]),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied for job!')));
    setState(() {});
  }

  Future<void> _saveJob(String jobId, List savedBy) async {
    if (user == null) return;
    if (savedBy.contains(user!.uid)) return;
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'savedBy': FieldValue.arrayUnion([user!.uid]),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job saved!')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Jobs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v == '' ? null : v),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _categoryFilter,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v == '' ? null : v),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _locationFilter,
                  hint: const Text('Location'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    ..._locations.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                  ],
                  onChanged: (v) => setState(() => _locationFilter = v == '' ? null : v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final jobs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  if (_searchQuery.isEmpty) return true;
                  return title.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());
                }).toList();
                if (jobs.isEmpty) {
                  return const Center(child: Text('No jobs available.'));
                }
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final data = job.data() as Map<String, dynamic>;
                    final applicants = List<String>.from(data['applicants'] ?? []);
                    final savedBy = List<String>.from(data['savedBy'] ?? []);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(applicants.contains(user?.uid) ? Icons.check : Icons.work_outline),
                              tooltip: applicants.contains(user?.uid) ? 'Applied' : 'Apply',
                              onPressed: applicants.contains(user?.uid) ? null : () => _applyForJob(job.id, applicants, status: data['status']),
                            ),
                            IconButton(
                              icon: Icon(savedBy.contains(user?.uid) ? Icons.bookmark : Icons.bookmark_border),
                              tooltip: savedBy.contains(user?.uid) ? 'Saved' : 'Save',
                              onPressed: savedBy.contains(user?.uid) ? null : () => _saveJob(job.id, savedBy),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailsScreen(jobId: job.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  String? _status;
  bool _isPoster = false;
  Map<String, dynamic>? _data;
  bool _editing = false;
  final _editFormKey = GlobalKey<FormState>();
  String? _editTitle, _editDescription, _editBudget, _editCategory, _editLocation;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      setState(() {
        _data = data;
        _status = data['status'] ?? 'Open';
        _isPoster = data['postedBy'] == FirebaseAuth.instance.currentUser?.uid;
      });
    }
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus == null) return;
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({'status': newStatus});
    setState(() => _status = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job status updated!')));
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _editTitle = _data!['title'];
      _editDescription = _data!['description'];
      _editBudget = _data!['budget'];
      _editCategory = _data!['category'];
      _editLocation = _data!['location'];
    });
  }

  Future<void> _saveEdit() async {
    if (!_editFormKey.currentState!.validate()) return;
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'title': _editTitle,
      'description': _editDescription,
      'budget': _editBudget,
      'category': _editCategory,
      'location': _editLocation,
    });
    setState(() {
      _editing = false;
      _data!['title'] = _editTitle;
      _data!['description'] = _editDescription;
      _data!['budget'] = _editBudget;
      _data!['category'] = _editCategory;
      _data!['location'] = _editLocation;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job updated!')));
  }

  Future<void> _deleteJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_data!['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Budget: ${_data!['budget'] ?? ''}'),
            const SizedBox(height: 12),
            Text(_data!['description'] ?? ''),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isPoster)
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'Open', child: Text('Open')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                    ],
                    onChanged: _updateStatus,
                  )
                else
                  Text(_status ?? ''),
              ],
            ),
            const SizedBox(height: 24),
            if (_isPoster && !_editing && _status != 'Closed')
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: _startEdit,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteJob,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Close Applications'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: () => _updateStatus('Closed'),
                  ),
                ],
              ),
            if (_isPoster && !_editing && _status == 'Closed')
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Re-Open Job'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _updateStatus('Open'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({'status': 'Archived'});
                      setState(() => _status = 'Archived');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job archived!')));
                    },
                  ),
                ],
              ),
            if (_editing)
              Form(
                key: _editFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _editTitle,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (v) => _editTitle = v,
                      validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                    ),
                    TextFormField(
                      initialValue: _editDescription,
                      decoration: const InputDecoration(labelText: 'Description'),
                      onChanged: (v) => _editDescription = v,
                      validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                    ),
                    TextFormField(
                      initialValue: _editBudget,
                      decoration: const InputDecoration(labelText: 'Budget'),
                      onChanged: (v) => _editBudget = v,
                      validator: (v) => v == null || v.isEmpty ? 'Budget required' : null,
                    ),
                    TextFormField(
                      initialValue: _editCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      onChanged: (v) => _editCategory = v,
                      validator: (v) => v == null || v.isEmpty ? 'Category required' : null,
                    ),
                    TextFormField(
                      initialValue: _editLocation,
                      decoration: const InputDecoration(labelText: 'Location'),
                      onChanged: (v) => _editLocation = v,
                      validator: (v) => v == null || v.isEmpty ? 'Location required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveEdit,
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => setState(() => _editing = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isPoster)
              ApplicantsList(applicants: List<String>.from(_data!['applicants'] ?? [])),
          ],
        ),
      ),
    );
  }
}

class ApplicantsList extends StatelessWidget {
  final List<String> applicants;
  const ApplicantsList({super.key, required this.applicants});

  @override
  Widget build(BuildContext context) {
    if (applicants.isEmpty) {
      return const Text('No applicants yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Applicants:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...applicants.map((uid) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data != null && data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: data == null || data['photoUrl'] == null || data['photoUrl'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(data?['displayName'] ?? 'Unknown'),
                  subtitle: Text(data?['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.message),
                    tooltip: 'Message Applicant',
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;
                      final userIds = [currentUser.uid, uid]..sort();
                      final chatQuery = await FirebaseFirestore.instance
                          .collection('chats')
                          .where('userIds', isEqualTo: userIds)
                          .limit(1)
                          .get();
                      String chatId;
                      if (chatQuery.docs.isNotEmpty) {
                        chatId = chatQuery.docs.first.id;
                      } else {
                        final docRef = await FirebaseFirestore.instance.collection('chats').add({
                          'userIds': userIds,
                          'lastMessage': '',
                          'lastTimestamp': FieldValue.serverTimestamp(),
                        });
                        chatId = docRef.id;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailsScreen(chatId: chatId, otherUserId: uid),
                        ),
                      );
                    },
                  ),
                );
              },
            )),
      ],
    );
  }
} 