import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  Map<String, dynamic>? doctor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorData();
    });
  }

  void _loadDoctorData() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        doctor = args;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: Text('Doctor information not found')),
      );
    }

    FirebaseAnalytics.instance.logScreenView(screenName: 'DoctorDetailsScreen');

    if (doctor != null && doctor!['name'] == 'Dr. Alice') {
      doctor!['imageAsset'] = 'assets/doctrine2.jpg';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Doctor Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${doctor!['name']} to favorites')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.feedback),
            tooltip: 'Send Feedback',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Feedback'),
                  content: Text('To report a doctor details issue, email support@smartcare.com or use the Contact Us option in the app drawer.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header
            Semantics(
              label: 'Doctor header. Name: ${doctor!['name']}, Specialty: ${doctor!['specialty']}, Rating: ${(doctor!['rating'] ?? 0.0).toStringAsFixed(1)}, ${doctor!['totalReviews'] ?? 0} reviews.',
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(doctor!['imageAsset'] ?? 'assets/doctor.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctor!['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor!['specialty'],
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        ' ${(doctor!['rating'] ?? 0.0).toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${doctor!['totalReviews'] ?? 0} reviews)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildSection(
                    title: 'About',
                    icon: Icons.person,
                    content: doctor!['about'] ?? 'No information available',
                  ),

                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSection(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildInfoRow(Icons.phone, 'Phone', doctor!['phone'] ?? 'Not available'),
                      _buildInfoRow(Icons.email, 'Email', doctor!['email'] ?? 'Not available'),
                      _buildInfoRow(Icons.location_on, 'Location', doctor!['location'] ?? 'Not available'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Professional Information
                  _buildSection(
                    title: 'Professional Information',
                    icon: Icons.work,
                    children: [
                      _buildInfoRow(Icons.schedule, 'Experience', doctor!['experience'] ?? 'Not available'),
                      _buildInfoRow(Icons.school, 'Education', doctor!['education'] ?? 'Not available'),
                      _buildInfoRow(Icons.attach_money, 'Consultation Fee', doctor!['consultationFee'] ?? 'Not available'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Languages
                  if (doctor!['languages'] != null)
                    _buildSection(
                      title: 'Languages',
                      icon: Icons.language,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: (doctor!['languages'] as List<dynamic>).map((language) {
                            return Chip(
                              label: Text(language),
                              backgroundColor: Colors.blue[100],
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Book Appointment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Ensure all required fields are present and provide defaults if missing
                        final bookingArgs = {
                          'id': doctor!['id'] ?? '',
                          'name': doctor!['name'] ?? '',
                          'specialty': doctor!['specialty'] ?? '',
                          'location': doctor!['location'] ?? '',
                          'imageAsset': doctor!['imageAsset'] ?? 'assets/doctor.png',
                          'phone': doctor!['phone'] ?? '',
                          'email': doctor!['email'] ?? '',
                          'consultationFee': doctor!['consultationFee'] ?? '',
                          // Add more fields as needed
                        };
                        Navigator.pushNamed(
                          context,
                          '/book_appointment',
                          arguments: bookingArgs,
                        );
                      },
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Call Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Call functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${doctor!['phone']}')),
                        );
                      },
                      child: const Text(
                        'Call Doctor',
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Important Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('• Please arrive 10 minutes before your appointment'),
                          const Text('• Bring your ID and insurance information'),
                          const Text('• You can cancel up to 24 hours before the appointment'),
                          const Text('• Consultation fee is payable at the clinic'),
                          const Text('• Emergency cases are prioritized'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? content,
    List<Widget>? children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(
                content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            if (children != null) ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 