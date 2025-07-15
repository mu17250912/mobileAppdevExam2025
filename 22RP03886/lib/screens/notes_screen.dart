import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';

class NotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, _) {
          final notes = noteProvider.notes;
          if (notes.isEmpty) {
            return Center(child: Text('No notes yet.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditNoteScreen(note: note),
                      ),
                    );
                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Note updated!')),
                      );
                    }
                  },
                  title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Note'),
                          content: Text('Are you sure you want to delete this note?'),
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
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(child: CircularProgressIndicator()),
                        );
                        await Provider.of<NoteProvider>(context, listen: false).deleteNote(note);
                        Navigator.pop(context); // Remove loading dialog
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNoteScreen()),
          );
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Note added!')),
            );
          }
        },
        backgroundColor: Color(0xFF6D8BFF),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    setState(() => _isSaving = true);
                    final note = Note(
                      title: _titleController.text,
                      content: _contentController.text,
                      dateCreated: DateTime.now(),
                    );
                    try {
                      await Provider.of<NoteProvider>(context, listen: false).addNote(note);
                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ' + e.toString())),
                      );
                    } finally {
                      setState(() => _isSaving = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6D8BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving ? CircularProgressIndicator(color: Colors.white) : Text('Save Note', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditNoteScreen extends StatefulWidget {
  final Note note;
  const EditNoteScreen({Key? key, required this.note}) : super(key: key);

  @override
  _EditNoteScreenState createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                    setState(() => _isSaving = true);
                    final updatedNote = Note(
                      docId: widget.note.docId,
                      id: widget.note.id,
                      title: _titleController.text,
                      content: _contentController.text,
                      dateCreated: widget.note.dateCreated,
                    );
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(child: CircularProgressIndicator()),
                      );
                      await Provider.of<NoteProvider>(context, listen: false).updateNote(updatedNote);
                      Navigator.pop(context); // Remove loading dialog
                      Navigator.pop(context, true);
                    } catch (e) {
                      Navigator.pop(context); // Remove loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ' + e.toString())),
                      );
                    } finally {
                      setState(() => _isSaving = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6D8BFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving ? CircularProgressIndicator(color: Colors.white) : Text('Save Changes', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 