import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AppliedJobsScreen extends StatelessWidget {
  const AppliedJobsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final jobs = [
      {'id': '1', 'title': 'Fix kitchen sink', 'category': 'Plumber', 'location': 'Nairobi', 'budget': 'KES 2,000'},
      {'id': '2', 'title': 'Design logo', 'category': 'Designer', 'location': 'Mombasa', 'budget': 'KES 5,000'},
      {'id': '3', 'title': 'Install shelves', 'category': 'Carpenter', 'location': 'Kisumu', 'budget': 'KES 3,500'},
    ];
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
              child: Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Applied Jobs',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final appliedJobs = jobs.where((job) => userProvider.hasApplied(job['id']!)).toList();
          if (appliedJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No applied jobs yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start applying for jobs to see them here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: appliedJobs.length,
            itemBuilder: (context, index) {
              final job = appliedJobs[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
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
                  title: Text(
                    job['title']!,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  job['category']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 16, color: colorScheme.secondary),
                                const SizedBox(width: 6),
                                Text(
                                  job['location']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final isSaved = userProvider.isJobSaved(job['id']!);
                          return IconButton(
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? Colors.amber : colorScheme.onSurface.withOpacity(0.6),
                            ),
                            tooltip: isSaved ? 'Unsave Job' : 'Save Job',
                            onPressed: () async {
                              if (isSaved) {
                                await userProvider.unsaveJob(job['id']!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed from saved jobs: ${job['title']}', style: GoogleFonts.poppins()),
                                    backgroundColor: colorScheme.surfaceVariant,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                await userProvider.saveJob(job['id']!);
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
                      Text(
                        job['budget']!,
                        style: GoogleFonts.poppins(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 