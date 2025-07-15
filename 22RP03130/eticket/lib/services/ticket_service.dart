import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket.dart';

class TicketService {
  final _tickets = FirebaseFirestore.instance.collection('tickets');

  Future<void> bookTicket(Ticket ticket) async {
    await _tickets.add(ticket.toMap());
  }

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _tickets.where('userId', isEqualTo: userId).snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Ticket.fromMap(doc.id, doc.data())).toList()
    );
  }

  // Add more methods as needed
} 