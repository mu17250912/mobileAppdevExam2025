import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/event.dart';
import 'models/ticket.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
// Conditional import for PDF export
import 'organizer_tickets_pdf_io.dart'
  if (dart.library.html) 'organizer_tickets_pdf_web.dart';

class OrganizerTicketsScreen extends StatefulWidget {
  const OrganizerTicketsScreen({super.key});

  @override
  State<OrganizerTicketsScreen> createState() => _OrganizerTicketsScreenState();
}

enum TicketSortField { purchaseDate, eventName }

class _OrganizerTicketsScreenState extends State<OrganizerTicketsScreen> {
  late String organizerId;
  bool _loading = true;
  List<Ticket> tickets = [];
  Map<String, Event> events = {};
  Map<String, Map<String, dynamic>> users = {};

  // Search/filter state
  String searchEmail = '';
  String? selectedEventId;
  DateTime? startDate;
  DateTime? endDate;

  // Pagination state
  int currentPage = 0;
  static const int pageSize = 10;

  // Sorting state
  TicketSortField sortField = TicketSortField.purchaseDate;
  bool sortAsc = false;

  @override
  void initState() {
    super.initState();
    organizerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    // 1. Get all events for this organizer
    final eventSnap = await FirebaseFirestore.instance
        .collection('events')
        .where('organizerId', isEqualTo: organizerId)
        .get();
    final eventIds = eventSnap.docs.map((doc) => doc.id).toList();
    events = {for (var doc in eventSnap.docs) doc.id: Event.fromMap(doc.id, doc.data())};
    if (eventIds.isEmpty) {
      setState(() {
        tickets = [];
        _loading = false;
      });
      return;
    }
    // 2. Get all tickets for these events
    final ticketSnap = await FirebaseFirestore.instance
        .collection('tickets')
        .where('eventId', whereIn: eventIds)
        .get();
    tickets = ticketSnap.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())).toList();
    // 3. Get user info for all ticket owners
    final userIds = tickets.map((t) => t.userId).toSet().toList();
    if (userIds.isNotEmpty) {
      final userSnaps = await Future.wait(userIds.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get()));
      users = {
        for (var snap in userSnaps)
          if (snap.exists) snap.id: snap.data() ?? {}
      };
    }
    setState(() => _loading = false);
  }

  List<Ticket> get filteredTickets {
    return tickets.where((ticket) {
      final user = users[ticket.userId];
      final event = events[ticket.eventId];
      final matchesEmail = searchEmail.isEmpty || (user?['email'] ?? '').toLowerCase().contains(searchEmail.toLowerCase());
      final matchesEvent = selectedEventId == null || ticket.eventId == selectedEventId;
      final matchesStart = startDate == null || !ticket.purchaseDate.isBefore(startDate!);
      final matchesEnd = endDate == null || !ticket.purchaseDate.isAfter(endDate!);
      return matchesEmail && matchesEvent && matchesStart && matchesEnd;
    }).toList();
  }

  List<Ticket> get sortedTickets {
    final list = [...filteredTickets];
    list.sort((a, b) {
      int cmp;
      if (sortField == TicketSortField.purchaseDate) {
        cmp = a.purchaseDate.compareTo(b.purchaseDate);
      } else {
        final eventA = events[a.eventId]?.title ?? '';
        final eventB = events[b.eventId]?.title ?? '';
        cmp = eventA.compareTo(eventB);
      }
      return sortAsc ? cmp : -cmp;
    });
    return list;
  }

  List<Ticket> get paginatedTickets {
    final start = currentPage * pageSize;
    final end = (start + pageSize).clamp(0, sortedTickets.length);
    return sortedTickets.sublist(start, end);
  }

  void _exportToCSVClipboard() {
    final csv = StringBuffer();
    csv.writeln('Event,Owner Name,Owner Email,Purchase Date');
    for (final ticket in sortedTickets) {
      final event = events[ticket.eventId];
      final user = users[ticket.userId];
      csv.writeln('"${event?.title ?? ''}","${user?['displayName'] ?? ''}","${user?['email'] ?? ''}","${ticket.purchaseDate.toLocal()}"');
    }
    Clipboard.setData(ClipboardData(text: csv.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket data copied to clipboard as CSV!')),
    );
  }

  Future<void> _exportToCSVFile() async {
    final csv = StringBuffer();
    csv.writeln('Event,Owner Name,Owner Email,Purchase Date');
    for (final ticket in sortedTickets) {
      final event = events[ticket.eventId];
      final user = users[ticket.userId];
      csv.writeln('"${event?.title ?? ''}","${user?['displayName'] ?? ''}","${user?['email'] ?? ''}","${ticket.purchaseDate.toLocal()}"');
    }
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'tickets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV file saved: ${file.path}')),
    );
  }

  Future<void> _exportToPDFFile() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Tickets for My Events', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Event', 'Owner Name', 'Owner Email', 'Purchase Date'],
                  data: [
                    for (final ticket in sortedTickets)
                      [
                        events[ticket.eventId]?.title ?? '',
                        users[ticket.userId]?['displayName'] ?? '',
                        users[ticket.userId]?['email'] ?? '',
                        DateFormat('yyyy-MM-dd HH:mm').format(ticket.purchaseDate),
                      ]
                  ],
                ),
              ],
            );
          },
        ),
      );
      final bytes = await pdf.save();
      final filename = 'tickets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      await exportTicketsPdf(context, bytes, filename);
    } catch (e, st) {
      print('PDF export error: \\${e}\n\\${st}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: \\${e}')),
      );
    }
  }

  Future<void> _printOrSharePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Tickets for My Events', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Event', 'Owner Name', 'Owner Email', 'Purchase Date'],
                  data: [
                    for (final ticket in sortedTickets)
                      [
                        events[ticket.eventId]?.title ?? '',
                        users[ticket.userId]?['displayName'] ?? '',
                        users[ticket.userId]?['email'] ?? '',
                        DateFormat('yyyy-MM-dd HH:mm').format(ticket.purchaseDate),
                      ]
                  ],
                ),
              ],
            );
          },
        ),
      );
      print('Opening print/share dialog for PDF...');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, st) {
      print('Print/share PDF error: \\${e}\n\\${st}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing/sharing PDF: \\${e}')),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: endDate ?? DateTime(2100),
    );
    if (picked != null) setState(() { startDate = picked; currentPage = 0; });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() { endDate = picked; currentPage = 0; });
  }

  void _onSort(TicketSortField field) {
    setState(() {
      if (sortField == field) {
        sortAsc = !sortAsc;
      } else {
        sortField = field;
        sortAsc = true;
      }
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedTickets.length / pageSize).ceil();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tickets for My Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to CSV (Clipboard)',
            onPressed: _loading || sortedTickets.isEmpty ? null : _exportToCSVClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Export to CSV File',
            onPressed: _loading || sortedTickets.isEmpty ? null : _exportToCSVFile,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download as PDF',
            onPressed: _loading || sortedTickets.isEmpty ? null : _exportToPDFFile,
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print/Share PDF',
              onPressed: _loading || sortedTickets.isEmpty ? null : _printOrSharePDF,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by user email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() { searchEmail = v; currentPage = 0; }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String?>(
                        value: selectedEventId,
                        hint: const Text('Filter by event'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Events'),
                          ),
                          ...events.entries.map((e) => DropdownMenuItem<String?>(
                                value: e.key,
                                child: Text(e.value.title),
                              )),
                        ],
                        onChanged: (v) => setState(() { selectedEventId = v; currentPage = 0; }),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _pickStartDate,
                        child: Text(startDate == null ? 'Start Date' : startDate!.toLocal().toString().split(' ')[0]),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _pickEndDate,
                        child: Text(endDate == null ? 'End Date' : endDate!.toLocal().toString().split(' ')[0]),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () => _onSort(TicketSortField.eventName),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Text('Event'),
                              if (sortField == TicketSortField.eventName)
                                Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: const Text('Owner Name'),
                      ),
                      Expanded(
                        flex: 2,
                        child: const Text('Owner Email'),
                      ),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () => _onSort(TicketSortField.purchaseDate),
                          child: Row(
                            children: [
                              const Text('Purchase Date'),
                              if (sortField == TicketSortField.purchaseDate)
                                Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: paginatedTickets.isEmpty
                      ? const Center(child: Text('No tickets found for your events.'))
                      : ListView.builder(
                          itemCount: paginatedTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = paginatedTickets[index];
                            final event = events[ticket.eventId];
                            final user = users[ticket.userId];
                            return Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Text(event?.title ?? 'Unknown Event'),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(user?['displayName'] ?? 'Unknown'),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(user?['email'] ?? ''),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(DateFormat('yyyy-MM-dd HH:mm').format(ticket.purchaseDate)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                        ),
                        Text('Page ${currentPage + 1} of $totalPages'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
} 