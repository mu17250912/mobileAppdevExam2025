import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategoryScreen extends StatefulWidget {
  @override
  _ManageCategoryScreenState createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  String? editingId;
  TextEditingController? editingController;

  @override
  void dispose() {
    editingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Categories')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No categories found.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final name = doc['name'] ?? '';
              final isEditing = editingId == doc.id;
              return Card(
                child: ListTile(
                  title: isEditing
                      ? TextField(
                          controller: editingController,
                          autofocus: true,
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'Category name'),
                        )
                      : Text(name, style: TextStyle(fontSize: 18)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing)
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          tooltip: 'Save',
                          onPressed: () async {
                            final newName = editingController?.text.trim() ?? '';
                            if (newName.isNotEmpty && newName != name) {
                              await doc.reference.update({'name': newName});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Category updated!')),
                              );
                            }
                            setState(() {
                              editingId = null;
                              editingController?.dispose();
                              editingController = null;
                            });
                          },
                        ),
                      if (isEditing)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          tooltip: 'Cancel',
                          onPressed: () {
                            setState(() {
                              editingId = null;
                              editingController?.dispose();
                              editingController = null;
                            });
                          },
                        ),
                      if (!isEditing)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () {
                            setState(() {
                              editingId = doc.id;
                              editingController?.dispose();
                              editingController = TextEditingController(text: name);
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Category'),
                              content: Text('Are you sure you want to delete this category?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await doc.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Category deleted!')),
                            );
                          }
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