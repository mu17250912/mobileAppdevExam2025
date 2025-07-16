import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FlaggedScreen extends StatefulWidget {
  final List<Map<String, dynamic>> flaggedQuestions;
  const FlaggedScreen({required this.flaggedQuestions});

  @override
  State<FlaggedScreen> createState() => _FlaggedScreenState();
}

class _FlaggedScreenState extends State<FlaggedScreen> {
  late List<Map<String, dynamic>> _flaggedQuestions;

  @override
  void initState() {
    super.initState();
    _flaggedQuestions = List<Map<String, dynamic>>.from(widget.flaggedQuestions);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final firestoreService = FirestoreService();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F8FFF), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Flagged Questions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _flaggedQuestions.isEmpty
            ? Center(child: Text('No flagged questions.', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)))
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: _flaggedQuestions.length,
                separatorBuilder: (context, index) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final q = _flaggedQuestions[index];
                  return Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(q['question'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              if (user != null)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Unflag',
                                  onPressed: () async {
                                    final qId = q['question'];
                                    final newFlagged = List<String>.from(userProvider.flaggedQuestions);
                                    newFlagged.remove(qId);
                                    await firestoreService.updateFlaggedQuestions(user.uid, newFlagged);
                                    userProvider.updateFlaggedQuestions(newFlagged);
                                    setState(() {
                                      if (index >= 0 && index < _flaggedQuestions.length) {
                                        _flaggedQuestions.removeAt(index);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if (q['explanation'] != null)
                            Text('Explanation: ${q['explanation']}', style: GoogleFonts.poppins(color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
} 