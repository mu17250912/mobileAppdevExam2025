import 'app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import '../../main.dart'; // for kGoldenBrown

class CompaniesScreen extends StatefulWidget {
  final String userId;
  const CompaniesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Companies'),
          backgroundColor: kGoldenBrown,
        ),
        drawer: AppDrawer(userId: '', isEmployer: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('userType', isEqualTo: 'employer').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: kGoldenBrown));
                }
                final companies = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final name = (data['companyName'] ?? '').toString().toLowerCase();
                  return _search.isEmpty || name.contains(_search);
                }).toList();
                if (companies.isEmpty) {
                  return const Center(child: Text('No companies found.'));
                }
                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    final data = company.data() as Map<String, dynamic>? ?? {};
                    final companyName = (data['companyName'] ?? '').toString();
                    final fallbackName = (data['name'] ?? '').toString();
                    final displayName = companyName.isNotEmpty ? companyName : (fallbackName.isNotEmpty ? fallbackName : 'Unknown Company');
                    final companyLogo = data['companyLogoUrl'] ?? data['profileImageUrl'];
                    final companyDesc = (data['companyDescription'] ?? '').toString();
                    final employerId = company.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (companyLogo != null && companyLogo != '') ? NetworkImage(companyLogo) : null,
                        child: (companyLogo == null || companyLogo == '')
                          ? (displayName.isNotEmpty && displayName != 'Unknown Company'
                              ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white))
                              : const Icon(Icons.business))
                          : null,
                      ),
                      title: Text(displayName),
                      subtitle: Text(companyDesc, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => CompanyProfileDialog(
                            userId: widget.userId,
                            employerId: employerId,
                            companyName: displayName,
                            companyLogo: companyLogo,
                            companyDesc: companyDesc,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kGoldenBrown,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1, // Companies tab index
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // Navigation handled by parent
        },
      ),
    );
  }
}

class CompanyProfileDialog extends StatelessWidget {
  final String userId;
  final String employerId;
  final String companyName;
  final String? companyLogo;
  final String companyDesc;
  const CompanyProfileDialog({Key? key, required this.userId, required this.employerId, required this.companyName, this.companyLogo, required this.companyDesc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (companyLogo != null && companyLogo != '') ? NetworkImage(companyLogo!) : null,
            child: (companyLogo == null || companyLogo == '')
              ? (companyName.isNotEmpty && companyName != 'Unknown Company'
                  ? Text(companyName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white))
                  : const Icon(Icons.business))
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      content: Text(companyDesc.isNotEmpty ? companyDesc : 'No description.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          style: ElevatedButton.styleFrom(backgroundColor: kGoldenBrown),
          label: const Text('Message'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatThreadScreen(
                  currentUserId: userId,
                  otherUserId: employerId,
                  otherUserName: companyName.isNotEmpty ? companyName : 'Unknown Company',
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 