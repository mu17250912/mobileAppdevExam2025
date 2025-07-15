import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for a skill...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Type to search for skills.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('skills')
                        .where('name', isGreaterThanOrEqualTo: _query)
                        .where('name', isLessThan: '${_query}z')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No skills found.'));
                      }
                      final skills = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: skills.length,
                        itemBuilder: (context, i) {
                          final skill =
                              skills[i].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.star),
                              title: Text(skill['name'] ?? ''),
                              subtitle: Text(skill['role'] ?? ''),
                              trailing: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Connect'),
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
    );
  }
}
