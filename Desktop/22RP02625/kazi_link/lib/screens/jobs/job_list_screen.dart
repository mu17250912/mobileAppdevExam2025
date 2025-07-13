import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../messaging/messaging_screen.dart';
import '../profile/profile_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../providers/user_provider.dart';
import 'applied_jobs_screen.dart';
import 'job_details_screen.dart';
import 'saved_jobs_screen.dart';
import '../../providers/notification_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  String selectedCategory = 'All';
  String sortBy = 'Latest';
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  final List<String> categories = [
    'All',
    'Plumber',
    'Designer',
    'Electrician',
    'Carpenter',
    'Painter',
    'Cleaner',
    'Other'
  ];

  final List<String> sortOptions = [
    'Latest',
    'Title',
    'Budget (High to Low)',
    'Budget (Low to High)',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

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
            Text(
              'Job Listings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Saved Jobs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedJobsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Applied Jobs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppliedJobsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        isSearching = value.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs by title, category, or location...',
                      hintStyle: GoogleFonts.poppins(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              items: categories.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => selectedCategory = value!);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Sort Filter
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: sortBy,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              items: sortOptions.map((option) => DropdownMenuItem(
                                value: option,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    option,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => sortBy = value!);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Job List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      'Error loading jobs: ${snapshot.error}',
                      colorScheme,
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return _buildLoadingState(colorScheme);
                  }
                  
                  final jobs = snapshot.data!.docs;
                  
                  // Filtering and sorting
                  List<QueryDocumentSnapshot> filteredJobs = jobs.where((doc) {
                    final job = doc.data() as Map<String, dynamic>;
                    return (selectedCategory == 'All' || job['category'] == selectedCategory) &&
                      (job['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                      job['category'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                      job['location'].toString().toLowerCase().contains(searchQuery.toLowerCase()));
                  }).toList();
                  
                  // Sorting
                  if (sortBy == 'Title') {
                    filteredJobs.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
                  } else if (sortBy == 'Budget (High to Low)') {
                    filteredJobs.sort((a, b) {
                      final aMap = a.data() as Map<String, dynamic>;
                      final bMap = b.data() as Map<String, dynamic>;
                      int aBudget = int.tryParse(aMap['budget'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      int bBudget = int.tryParse(bMap['budget'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      return bBudget.compareTo(aBudget);
                    });
                  } else if (sortBy == 'Budget (Low to High)') {
                    filteredJobs.sort((a, b) {
                      final aMap = a.data() as Map<String, dynamic>;
                      final bMap = b.data() as Map<String, dynamic>;
                      int aBudget = int.tryParse(aMap['budget'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      int bBudget = int.tryParse(bMap['budget'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      return aBudget.compareTo(bBudget);
                    });
                  }
                  
                  if (filteredJobs.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredJobs[index];
                      final job = doc.data() as Map<String, dynamic>;
                      final jobId = doc.id;
                      final isPremium = job['premium'] == true;
                      final hasApplied = Provider.of<UserProvider>(context, listen: false).hasApplied(jobId);
                      
                      return _buildJobCard(
                        context,
                        job,
                        jobId,
                        isPremium,
                        hasApplied,
                        colorScheme,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagingScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        height: 68,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
    bool isPremium,
    bool hasApplied,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(
                job: job.map((k, v) => MapEntry(k.toString(), v.toString())),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and premium badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Category and location chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    job['category'],
                    Icons.category,
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.1),
                  ),
                  _buildChip(
                    job['location'],
                    Icons.location_on,
                    colorScheme.secondary,
                    colorScheme.secondary.withOpacity(0.1),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Budget and actions row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['budget'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save/Unsave button
                      IconButton(
                        icon: Icon(
                          Provider.of<UserProvider>(context, listen: false).isJobSaved(jobId)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Provider.of<UserProvider>(context, listen: false).isJobSaved(jobId)
                              ? Colors.amber
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () async {
                          if (Provider.of<UserProvider>(context, listen: false).isJobSaved(jobId)) {
                            await Provider.of<UserProvider>(context, listen: false).unsaveJob(jobId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed from saved jobs: ${job['title']}'),
                                  backgroundColor: colorScheme.surfaceVariant,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            await Provider.of<UserProvider>(context, listen: false).saveJob(jobId);
                            Provider.of<NotificationProvider>(context, listen: false)
                                .addJobUpdateNotification(job['title']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Saved job: ${job['title']}'),
                                  backgroundColor: colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Apply/Withdraw button
                      ElevatedButton(
                        onPressed: () => _handleJobAction(context, job, jobId, hasApplied),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasApplied
                              ? colorScheme.error
                              : colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          hasApplied ? 'Withdraw' : 'Apply',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading jobs...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: Text('Try Again', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
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

  Future<void> _handleJobAction(BuildContext context, Map<String, dynamic> job, String jobId, bool hasApplied) async {
    if (hasApplied) {
      // Withdraw application
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Withdraw Application', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to withdraw your application for "${job['title']}"?',
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
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text('Withdraw', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        await Provider.of<UserProvider>(context, listen: false).withdrawApplication(jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Application withdrawn for ${job['title']}!'),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Apply for job
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Apply for Job', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to apply for "${job['title']}"?',
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
        final success = await Provider.of<UserProvider>(context, listen: false).applyForJob(jobId);
        if (!success) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Go Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Applied for ${job['title']}!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }
}