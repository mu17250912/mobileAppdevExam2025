import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../messaging/messaging_screen.dart';
import '../../providers/notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, String> job;
  const JobDetailsScreen({Key? key, required this.job}) : super(key: key);

  Future<void> updateJob(BuildContext context, String jobId) async {
    // Simulate updating the job in Firestore (add your real update logic here)
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'description': 'Updated job description',
      // ...other fields to update
    });
    // Notify all applicants
    await NotificationProvider.notifyApplicants(
      jobId,
      NotificationItem(
        id: '',
        icon: Icons.work,
        title: 'Job Updated',
        message: 'A job you applied for has been updated!',
        time: 'Just now',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job updated and applicants notified!', style: GoogleFonts.poppins())),
    );
  }

  void _showEditJobDialog(BuildContext context, String jobId, Map<String, String> job) {
    final descController = TextEditingController(text: job['description']);
    final categoryController = TextEditingController(text: job['category']);
    final budgetController = TextEditingController(text: job['budget']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Job', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
                'description': descController.text,
                'category': categoryController.text,
                'budget': budgetController.text,
              });
              await NotificationProvider.notifyApplicants(
                jobId,
                NotificationItem(
                  id: '',
                  icon: Icons.work,
                  title: 'Job Updated',
                  message: 'A job you applied for has been updated!',
                  time: 'Just now',
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Job updated and applicants notified!', style: GoogleFonts.poppins())),
              );
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobId = job['id']!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.work, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                job['title']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final isSaved = userProvider.isJobSaved(jobId);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : colorScheme.onSurface,
                ),
                tooltip: isSaved ? 'Unsave Job' : 'Save Job',
                onPressed: () async {
                  if (isSaved) {
                    await userProvider.unsaveJob(jobId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed from saved jobs: ${job['title']}', style: GoogleFonts.poppins()),
                        backgroundColor: colorScheme.surfaceVariant,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    await userProvider.saveJob(jobId);
                    // Trigger a notification for demo
                    Provider.of<NotificationProvider>(context, listen: false)
                        .addJobUpdateNotification(job['title']!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved job: ${job['title']}', style: GoogleFonts.poppins()),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final hasApplied = userProvider.hasApplied(jobId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Icon(
                                job['category'] == 'Plumber'
                                    ? Icons.plumbing
                                    : job['category'] == 'Designer'
                                        ? Icons.design_services
                                        : Icons.handyman,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              job['category']!,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Location: ${job['location']!}',
                              style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Budget: ${job['budget']!}',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Job Description:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This is a detailed description for the job: ${job['title']!}. (You can expand this with real data.)',
                      style: GoogleFonts.poppins(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: hasApplied
                          ? ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Withdraw Application', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    content: Text(
                                      'Are you sure you want to withdraw your application for ${job['title']}?',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.poppins()),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.error,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Withdraw', style: GoogleFonts.poppins()),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await userProvider.withdrawApplication(jobId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Application withdrawn for ${job['title']}!', style: GoogleFonts.poppins()),
                                      backgroundColor: colorScheme.surfaceVariant,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Withdraw Application'),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Apply for Job', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    content: Text(
                                      'Are you sure you want to apply for ${job['title']}?',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.poppins()),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Apply', style: GoogleFonts.poppins()),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await userProvider.applyForJob(jobId);
                                  if (!success) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Go Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                        content: Text(
                                          'Upgrade to premium for unlimited job applications!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: GoogleFonts.poppins()),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.pushNamed(context, '/premium');
                                            },
                                            child: Text('Go Premium', style: GoogleFonts.poppins()),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Applied for ${job['title']}!', style: GoogleFonts.poppins()),
                                        backgroundColor: colorScheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Apply for Job'),
                            ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: Text('Message', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagingScreen(jobId: jobId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await updateJob(context, jobId);
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update Job'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _showEditJobDialog(context, jobId, job);
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Edit Job'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 