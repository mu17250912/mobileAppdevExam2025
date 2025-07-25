import 'package:flutter/material.dart';
import '../services/medication_service.dart';
import '../services/reminder_service.dart';
import '../services/mock_database.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'meds_export_stub.dart'
    if (dart.library.html) 'meds_export_web.dart';

class MyMedsScreen extends StatelessWidget {
  void _markReminderAsTaken(
    BuildContext context,
    String medId,
    String reminderId,
  ) async {
    // Mark the reminder as taken in Firestore
    await ReminderService().updateReminder(medId, reminderId, {
      'status': 'taken',
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Marked as taken!')));
  }

  final VoidCallback? onBackToHome;
  const MyMedsScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final MedicationService medService = MedicationService();
    final isPremium = context.watch<AppState>().isPremium;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Meds'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBackToHome ?? () {},
        ),
      ),
      backgroundColor: Color(0xFFE6EDFF),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: medService.getMedications(),
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                final docs = snapshot.data.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('No medications yet. Add one!'));
                }
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final med = docs[index].data();
                    Color statusColor;
                    String statusText;
                    switch (med['status']) {
                      case 'taken':
                        statusColor = Colors.green;
                        statusText = 'Taken';
                        break;
                      case 'missed':
                        statusColor = Colors.red;
                        statusText = 'Missed';
                        break;
                      case 'snoozed':
                        statusColor = Colors.blue;
                        statusText = 'Snoozed';
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusText = 'Pending';
                    }
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Icon(
                          Icons.medication,
                          color: Colors.blueAccent,
                          size: 36,
                        ),
                        title: Text(
                          med['name'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${med['dosage']} • ${med['frequency']}\n${med['time']}',
                          style: TextStyle(height: 1.5),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor),
                              ),
                            ),
                            SizedBox(width: 8),
                            if (med['status'] != 'taken')
                              IconButton(
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                tooltip: 'Mark as taken',
                                onPressed: () async {
                                  // Find the reminderId for this medication (assuming 1:1 for demo)
                                  final remindersSnapshot =
                                      await ReminderService()
                                          .getReminders(docs[index].id)
                                          .first;
                                  if (remindersSnapshot.docs.isNotEmpty) {
                                    final reminderId =
                                        remindersSnapshot.docs.first.id;
                                    _markReminderAsTaken(
                                      context,
                                      docs[index].id,
                                      reminderId,
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (context) => Container(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Medication Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text('Name: ${med['name']}'),
                                  Text('Dosage: ${med['dosage']}'),
                                  Text('Frequency: ${med['frequency']}'),
                                  Text('Time: ${med['time']}'),
                                  Text('Status: $statusText'),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                        ),
                                        label: Text('Edit'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                EditMedicationDialog(
                                                  med: Medication(
                                                    name: med['name'],
                                                    dosage: med['dosage'],
                                                    frequency: med['frequency'],
                                                    time: med['time'],
                                                    status: med['status'],
                                                  ),
                                                ),
                                          ).then((updatedMed) async {
                                            if (updatedMed != null) {
                                              // Actually update medication in Firestore
                                              try {
                                                await medService
                                                    .updateMedication(
                                                      docs[index].id,
                                                      {
                                                        'name': updatedMed.name,
                                                        'dosage':
                                                            updatedMed.dosage,
                                                        'frequency': updatedMed
                                                            .frequency,
                                                        'time': updatedMed.time,
                                                        'status':
                                                            updatedMed.status,
                                                      },
                                                    );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Medication updated!',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to update medication.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: Text('Delete'),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete Medication'),
                                              content: Text(
                                                'Are you sure you want to delete this medication?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    try {
                                                      await medService
                                                          .deleteMedication(
                                                            docs[index].id,
                                                          );
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Medication deleted!',
                                                          ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to delete medication.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Medication'),
                              content: Text(
                                'Are you sure you want to delete this medication?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await medService.deleteMedication(
                                        docs[index].id,
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Medication deleted!'),
                                        ),
                                      );
                                    } catch (e) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to delete medication.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(),
                Text(
                  isPremium
                      ? 'You are a Premium user! Enjoy exporting your medication report.'
                      : 'Exporting medication report is a Premium feature.',
                  style: TextStyle(
                    color: isPremium ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(isPremium ? Icons.download : Icons.lock),
                  label: Text(
                    isPremium
                        ? 'Export Medication Report'
                        : 'Export Report (Premium)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
                  onPressed: isPremium
                      ? () async {
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'export_medication_report',
                            parameters: {'user': 'premium'},
                          );
                          try {
                            final medService = MedicationService();
                            final snapshot = await medService
                                .getMedications()
                                .first;
                            final meds = snapshot.docs
                                .map(
                                  (doc) => doc.data() as Map<String, dynamic>?,
                                )
                                .where((med) => med != null)
                                .toList();
                            final pdf = pw.Document();
                            pdf.addPage(
                              pw.Page(
                                build: (pw.Context context) {
                                  return pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Medication Report',
                                        style: pw.TextStyle(
                                          fontSize: 24,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 16),
                                      ...meds.map(
                                        (med) => pw.Container(
                                          margin: const pw.EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: pw.Text(
                                            'Name: ${med!['name'] ?? ''}\nDosage: ${med['dosage'] ?? ''}\nFrequency: ${med['frequency'] ?? ''}\nTime: ${med['time'] ?? ''}\nStatus: ${med['status'] ?? ''}',
                                            style: pw.TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                            if (kIsWeb) {
                              final bytes = await pdf.save();
                              exportPdfWeb(bytes, 'medication_report.pdf');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Report downloaded (web)!'),
                                ),
                              );
                            } else {
                              // Mobile/Desktop: save to app documents directory
                              final output =
                                  await getApplicationDocumentsDirectory();
                              final file = File(
                                '${output.path}/medication_report.pdf',
                              );
                              await file.writeAsBytes(await pdf.save());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Report exported to: ${file.path}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to export report: $e'),
                              ),
                            );
                          }
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Upgrade to premium to export reports!',
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_medication'),
        backgroundColor: Colors.blueAccent,
        tooltip: 'Add Medication',
        child: Icon(Icons.add),
      ),
    );
  }
}

class EditMedicationDialog extends StatefulWidget {
  final Medication med;
  const EditMedicationDialog({super.key, required this.med});

  @override
  State<EditMedicationDialog> createState() => _EditMedicationDialogState();
}

class _EditMedicationDialogState extends State<EditMedicationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _timeController;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.med.name);
    _dosageController = TextEditingController(text: widget.med.dosage);
    _timeController = TextEditingController(text: widget.med.time);
    _frequency = widget.med.frequency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Medication Name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(labelText: 'Dosage'),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              items: [
                'Once daily',
                'Twice daily',
                'Three times daily',
                'Weekly',
              ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) => setState(() => _frequency = val!),
              decoration: InputDecoration(labelText: 'Frequency'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Time (e.g. 8:00 AM)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedMed = Medication(
              name: _nameController.text.trim(),
              dosage: _dosageController.text.trim(),
              frequency: _frequency,
              time: _timeController.text.trim(),
              status: widget.med.status,
            );
            Navigator.pop(context, updatedMed);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
