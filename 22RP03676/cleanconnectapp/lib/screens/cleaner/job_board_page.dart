import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class CleanerJobBoardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: CleanerJobBoardPage build. user: ' + (user?.uid ?? 'null') + ', email: ' + (user?.email ?? 'null'));
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
        backgroundColor: const Color(0xFF6A8DFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', isEqualTo: 'open')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print('DEBUG: Cleaner user: ' + (user.uid ?? 'null') + ', email: ' + (user.email ?? 'null'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('DEBUG: No open jobs found for cleaner.');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cleaning_services, size: 64, color: Color(0xFF6A8DFF)),
                  SizedBox(height: 18),
                  Text('No open jobs at the moment.', style: TextStyle(fontSize: 18, color: Colors.black54)),
                ],
              ),
            );
          }
          final jobs = snapshot.data!.docs;
          print('DEBUG: Found \'${jobs.length}\' open jobs for cleaner. Titles: ' + jobs.map((doc) => (doc.data() as Map<String, dynamic>)['title']).join(', '));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, i) {
              final job = jobs[i].data() as Map<String, dynamic>;
              final jobId = jobs[i].id;
              final applicants = (job['applicants'] as List?)?.cast<String>() ?? [];
              final hasApplied = applicants.contains(user.uid);
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cleaning_services, color: Color(0xFF6A8DFF), size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job['description'] ?? '',
                              style: const TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatefulBuilder(
                        builder: (context, setState) {
                          bool isLoading = false;
                          return ElevatedButton(
                            onPressed: hasApplied || isLoading
                                ? null
                                : () async {
                                    print('DEBUG: Apply for Job button pressed!');
                                    // Use Provider to check premium status
                                    final isPremium = Provider.of<UserProvider>(context, listen: false).isPremium;
                                    if (!isPremium) {
                                      // Show paywall dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Premium Feature'),
                                          content: const Text('Applying for jobs is a premium feature. Please subscribe to unlock unlimited applications.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.pushNamed(context, '/subscribe');
                                              },
                                              child: const Text('Subscribe'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    final nameController = TextEditingController(text: user.displayName ?? '');
                                    final emailController = TextEditingController(text: user.email ?? '');
                                    final phoneController = TextEditingController();
                                    final messageController = TextEditingController();
                                    final customQuestions = (job['customQuestions'] as List?)?.cast<String>() ?? [];
                                    final customQuestionControllers = customQuestions.map((q) => TextEditingController()).toList();
                                    await FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
                                      if (doc.exists) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        if (data['phone'] != null) {
                                          phoneController.text = data['phone'];
                                        }
                                      }
                                    });
                                    final formKey = GlobalKey<FormState>();
                                    bool agreed = false;
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (dialogContext) {
                                        final title = job['title'] ?? '';
                                        final location = job['location'] ?? '';
                                        final payRate = job['payRate'] ?? '';
                                        String dateStr = '';
                                        if (job['date'] != null) {
                                          if (job['date'] is Timestamp) {
                                            final dt = (job['date'] as Timestamp).toDate();
                                            dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                                          } else if (job['date'] is DateTime) {
                                            final dt = job['date'] as DateTime;
                                            dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                                          } else if (job['date'] is String) {
                                            dateStr = job['date'];
                                          }
                                        }
                                        final time = job['time'] ?? '';
                                        return StatefulBuilder(
                                          builder: (dialogContext, setDialogState) => AlertDialog(
                                            title: const Text('Apply for Job'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Card(
                                                    color: const Color(0xFFF5F7FA),
                                                    margin: const EdgeInsets.only(bottom: 16),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                          if (location.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                                                                  const SizedBox(width: 4),
                                                                  Text(location, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                                ],
                                                              ),
                                                            ),
                                                          if (dateStr.isNotEmpty || (time != null && time != ''))
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                                                  const SizedBox(width: 4),
                                                                  Text(dateStr, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                                  if (time != null && time != '') ...[
                                                                    const SizedBox(width: 8),
                                                                    const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                                                    const SizedBox(width: 2),
                                                                    Text(time, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                          if (payRate.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(Icons.attach_money, size: 16, color: Colors.blueGrey),
                                                                  const SizedBox(width: 4),
                                                                  Text('Pay: $payRate', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Form(
                                                    key: formKey,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        TextFormField(
                                                          controller: nameController,
                                                          decoration: const InputDecoration(labelText: 'Name'),
                                                          validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                                                        ),
                                                        const SizedBox(height: 12),
                                                        TextFormField(
                                                          controller: emailController,
                                                          decoration: const InputDecoration(labelText: 'Email'),
                                                          validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                                                        ),
                                                        const SizedBox(height: 12),
                                                        TextFormField(
                                                          controller: phoneController,
                                                          decoration: const InputDecoration(labelText: 'Phone'),
                                                          validator: (v) => v == null || v.isEmpty ? 'Enter your phone number' : null,
                                                        ),
                                                        const SizedBox(height: 12),
                                                        TextFormField(
                                                          controller: messageController,
                                                          decoration: const InputDecoration(labelText: 'Message (optional)'),
                                                          maxLines: 2,
                                                        ),
                                                        if (customQuestions.isNotEmpty) ...[
                                                          const SizedBox(height: 16),
                                                          const Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Text('Additional Questions', style: TextStyle(fontWeight: FontWeight.bold)),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          for (int i = 0; i < customQuestions.length; i++)
                                                            Padding(
                                                              padding: const EdgeInsets.only(bottom: 10),
                                                              child: TextFormField(
                                                                controller: customQuestionControllers[i],
                                                                decoration: InputDecoration(labelText: customQuestions[i]),
                                                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                                              ),
                                                            ),
                                                        ],
                                                        const SizedBox(height: 16),
                                                        Row(
                                                          children: [
                                                            Checkbox(
                                                              value: agreed,
                                                              onChanged: (v) {
                                                                setDialogState(() {
                                                                  agreed = v ?? false;
                                                                });
                                                              },
                                                            ),
                                                            const Expanded(
                                                              child: Text(
                                                                'I agree to the terms and conditions.',
                                                                style: TextStyle(fontSize: 13),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  if (Navigator.of(dialogContext).canPop()) {
                                                    Navigator.of(dialogContext).pop();
                                                  }
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: agreed
                                                    ? () {
                                                        print('DEBUG: Apply button pressed!');
                                                        if (formKey.currentState!.validate()) {
                                                          final customAnswers = <String, String>{};
                                                          for (int i = 0; i < customQuestions.length; i++) {
                                                            customAnswers[customQuestions[i]] = customQuestionControllers[i].text.trim();
                                                          }
                                                          if (Navigator.of(dialogContext).canPop()) {
                                                            Navigator.of(dialogContext).pop({
                                                              'name': nameController.text.trim(),
                                                              'email': emailController.text.trim(),
                                                              'phone': phoneController.text.trim(),
                                                              'message': messageController.text.trim(),
                                                              'appliedAt': DateTime.now().toIso8601String(),
                                                              if (customAnswers.isNotEmpty) 'customAnswers': customAnswers,
                                                            });
                                                          }
                                                        }
                                                      }
                                                    : null,
                                                child: const Text('Apply'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                    if (result != null) {
                                      setState(() => isLoading = true);
                                      await FirebaseFirestore.instance
                                          .collection('jobs')
                                          .doc(jobId)
                                          .collection('applicants')
                                          .doc(user.uid)
                                          .set({
                                            ...result,
                                            'status': 'pending',
                                          });
                                      await FirebaseFirestore.instance
                                          .collection('jobs')
                                          .doc(jobId)
                                          .update({
                                            'applicants': FieldValue.arrayUnion([user.uid]),
                                          });
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Applied for job!')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasApplied ? Colors.grey : const Color(0xFF6A8DFF),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Builder(
                              builder: (context) {
                                final isPremium = Provider.of<UserProvider>(context).isPremium;
                                if (hasApplied) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('jobs')
                                        .doc(jobId)
                                        .collection('applicants')
                                        .doc(user.uid)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                            SizedBox(width: 4),
                                            Text('Applied'),
                                          ],
                                        );
                                      }
                                      final status = (snapshot.data?.data() as Map<String, dynamic>?)?['status'] ?? 'Applied';
                                      IconData icon = Icons.check;
                                      Color color = Colors.white;
                                      String label = 'Applied';
                                      if (status == 'pending') {
                                        icon = Icons.hourglass_top;
                                        color = Colors.amberAccent;
                                        label = 'Pending';
                                      } else if (status == 'accepted') {
                                        icon = Icons.check_circle;
                                        color = Colors.greenAccent;
                                        label = 'Accepted';
                                      } else if (status == 'rejected') {
                                        icon = Icons.cancel;
                                        color = Colors.redAccent;
                                        label = 'Rejected';
                                      }
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, size: 18, color: color),
                                          const SizedBox(width: 4),
                                          Text(label),
                                        ],
                                      );
                                    },
                                  );
                                } else if (!isPremium) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.lock, size: 16),
                                      SizedBox(width: 4),
                                      Text('Apply'),
                                    ],
                                  );
                                } else {
                                  return const Text('Apply');
                                }
                              },
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
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  const _JobCard({required this.job, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final service = job['service'] ?? '';
    final customer = job['customerName'] ?? '';
    final dateObj = job['date'] is Timestamp
        ? (job['date'] as Timestamp).toDate()
        : DateTime.tryParse(job['date'] ?? '');
    final dateStr = dateObj != null
        ? '${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}'
        : '';
    final time = job['time'] ?? '';
    final location = job['location'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.cleaning_services, color: Color(0xFF6A8DFF)),
        title: Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.isNotEmpty)
              Text('Customer: $customer', style: const TextStyle(color: Colors.black54)),
            if (location.isNotEmpty)
              Text('Location: $location', style: const TextStyle(color: Colors.black54)),
            Text('$dateStr at $time'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            try {
              await FirebaseFirestore.instance.collection('bookings').doc(jobId).update({
                'status': 'accepted',
                'cleanerId': user.uid,
                'cleanerName': user.displayName ?? '',
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job accepted!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to accept job: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A8DFF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Accept'),
        ),
      ),
    );
  }
} 