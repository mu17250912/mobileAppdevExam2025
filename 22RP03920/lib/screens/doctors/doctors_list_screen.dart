import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> specialties = [
    'All', 'General', 'Cardiologist', 'Dentist', 'Gynecologist', 'Pediatrics', 'Orthopedic'
  ];
  String selectedSpecialty = 'All';
  String searchQuery = '';

  Stream<QuerySnapshot> _getDoctorsStream() {
    if (selectedSpecialty == 'All') {
      return _firestoreService.doctorsCollection.snapshots();
    } else {
      return _firestoreService.doctorsCollection
          .where('specialty', isEqualTo: selectedSpecialty)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(screenName: 'DoctorsListScreen');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('All Doctors'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: Icon(Icons.feedback),
            tooltip: 'Send Feedback',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Feedback'),
                  content: Text('To report a doctor search issue, email support@smartcare.com or use the Contact Us option in the app drawer.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search doctor...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: specialties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = specialties[i] == selectedSpecialty;
                  return FilterChip(
                    label: Text(specialties[i]),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedSpecialty = specialties[i];
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getDoctorsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final doctors = snapshot.data!.docs;
                  final filteredDoctors = doctors.where((doc) {
                    final doctor = doc.data() as Map<String, dynamic>;
                    final name = doctor['name'] as String? ?? '';
                    final specialty = doctor['specialty'] as String? ?? '';
                    final location = doctor['location'] as String? ?? '';
                    final searchLower = searchQuery.toLowerCase();

                    return name.toLowerCase().contains(searchLower) ||
                           specialty.toLowerCase().contains(searchLower) ||
                           location.toLowerCase().contains(searchLower);
                  }).toList();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${filteredDoctors.length} found', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredDoctors.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No doctors found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                    Text('Try adjusting your search criteria', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = filteredDoctors[index].data() as Map<String, dynamic>;
                                  final doctorId = filteredDoctors[index].id;
                                  doctor['id'] = doctorId;

                                  return _DoctorCard(
                                    doctor: doctor,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/doctor_details',
                                      arguments: doctor,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctor,
    required this.onTap,
  });

  String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[1][0];
    }
    return name[0];
  }

  @override
  Widget build(BuildContext context) {
    final name = doctor['name'] ?? '';
    final specialty = doctor['specialty'] ?? '';
    final location = doctor['location'] ?? '';
    final rating = (doctor['rating'] ?? 0.0) as double;
    final reviews = (doctor['totalReviews'] ?? 0) as int;
    final imageAsset = doctor['imageAsset'] ?? '';
    final about = doctor['about'] ?? '';
    final isActive = doctor['isActive'] ?? true;

    return Semantics(
      label: 'Doctor card. Name: $name, Specialty: $specialty, Location: $location, Rating: $rating stars, $reviews reviews.',
      child: Card(
      color: const Color(0xF1F6FAFF),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isActive ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.asset(
                  imageAsset,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.purple[50],
                    alignment: Alignment.center,
                    child: Text(
                      getInitials(name),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Unavailable',
                              style: TextStyle(color: Colors.red[700], fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    Text(specialty, style: const TextStyle(fontSize: 16)),
                    Text(location, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text('${rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(' ($reviews Reviews)', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(about, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Color(0xFF3A3541)),
                onPressed: () {},
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
} 