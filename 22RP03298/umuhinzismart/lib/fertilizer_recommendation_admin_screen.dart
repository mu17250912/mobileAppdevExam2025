import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/loading_widget.dart';
import 'widgets/error_widget.dart';

class FertilizerRecommendationAdminScreen extends StatefulWidget {
  const FertilizerRecommendationAdminScreen({super.key});

  @override
  State<FertilizerRecommendationAdminScreen> createState() => _FertilizerRecommendationAdminScreenState();
}

class _FertilizerRecommendationAdminScreenState extends State<FertilizerRecommendationAdminScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<List<Map<String, dynamic>>> _fetchRecommendations() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('fertilizer_recommendations').get();
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load recommendations: $e');
      return [];
    }
  }

  Future<void> _showEditDialog({Map<String, dynamic>? rec}) async {
    final cropController = TextEditingController(text: rec?['crop'] ?? '');
    final weekController = TextEditingController(text: rec?['week'] ?? '');
    final nameController = TextEditingController(text: rec?['name'] ?? '');
    final detailsController = TextEditingController(text: rec?['details'] ?? '');
    final imageUrlController = TextEditingController(text: rec?['imageUrl'] ?? '');
    final isEdit = rec != null;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Recommendation' : 'Add Recommendation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cropController,
                decoration: const InputDecoration(labelText: 'Crop', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weekController,
                decoration: const InputDecoration(labelText: 'Week/Stage', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Fertilizer Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'crop': cropController.text.trim(),
                'week': weekController.text.trim(),
                'name': nameController.text.trim(),
                'details': detailsController.text.trim(),
                'imageUrl': imageUrlController.text.trim(),
              };
              setState(() => _isLoading = true);
              try {
                if (isEdit) {
                  await FirebaseFirestore.instance.collection('fertilizer_recommendations').doc(rec!['id']).update(data);
                } else {
                  await FirebaseFirestore.instance.collection('fertilizer_recommendations').add(data);
                }
                if (mounted) Navigator.pop(context);
                setState(() => _isLoading = false);
              } catch (e) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to save: $e';
                });
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecommendation(String id) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('fertilizer_recommendations').doc(id).delete();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Recommendations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchRecommendations(),
            builder: (context, snapshot) {
              if (_isLoading) {
                return const LoadingWidget(message: 'Loading...');
              }
              if (_errorMessage != null) {
                return CustomErrorWidget(message: _errorMessage!);
              }
              final recs = snapshot.data ?? [];
              if (recs.isEmpty) {
                return EmptyStateWidget(
                  message: 'No recommendations found.',
                  title: 'Empty',
                  icon: Icons.recommend,
                  onAction: () => _showEditDialog(),
                  actionText: 'Add Recommendation',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: recs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final rec = recs[i];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: rec['imageUrl'] != null && rec['imageUrl'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(rec['imageUrl'], width: 48, height: 48, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.recommend, size: 40, color: Colors.deepPurple),
                      title: Text('${rec['crop']} - ${rec['week']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${rec['name']}\n${rec['details']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(rec: rec),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRecommendation(rec['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            const LoadingWidget(message: 'Processing...'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Recommendation'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
} 