import 'package:flutter/material.dart';
import 'models/event.dart';
import 'models/ticket.dart';
import 'services/ticket_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketBookingScreen extends StatefulWidget {
  final Event event;
  const TicketBookingScreen({super.key, required this.event});


  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  bool _loading = false;
  String? _successMessage;
  String _selectedType = 'standard';

  Future<void> _bookTicket() async {
    setState(() {
      _loading = true;
      _successMessage = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ticket = Ticket(
      id: '',
      eventId: widget.event.id,
      userId: user.uid,
      purchaseDate: DateTime.now(),
      type: _selectedType,
    );
    await TicketService().bookTicket(ticket);
    setState(() {
      _loading = false;
      _successMessage = 'Ticket booked for \\${widget.event.title}!';
    });
  }

  Future<void> _simulatePaymentAndBookTicket() async {
    final event = widget.event;
    final price = _selectedType == 'premium' && event.hasPremium && event.premiumTicketPrice != null
        ? event.premiumTicketPrice!
        : event.ticketPrice;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool paying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Simulate Payment'),
              content: paying
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing payment...'),
                      ],
                    )
                  : Text('Ticket type: \\${_selectedType == 'premium' ? 'Premium' : 'Standard'}\nPrice: \\${price.toStringAsFixed(2)}'),
              actions: [
                if (!paying)
                  TextButton(
                    onPressed: () async {
                      setState(() => paying = true);
                      await Future.delayed(const Duration(seconds: 2));
                      Navigator.of(context).pop(true);
                    },
                    child: Text('Pay \\${price.toStringAsFixed(2)}'),
                  ),
                if (!paying)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
              ],
            );
          },
        );
      },
    );
    if (result == true) {
      await _bookTicket();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      appBar: AppBar(title: Text('Book Ticket for \\${event.title}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.hasPremium && event.premiumTicketPrice != null) ...[
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Standard (\\${event.ticketPrice.toStringAsFixed(2)})'),
                      value: 'standard',
                      groupValue: _selectedType,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Premium (\\${event.premiumTicketPrice!.toStringAsFixed(2)})'),
                      value: 'premium',
                      groupValue: _selectedType,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
            Text('Event: \\${event.title}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text('Date: \\${event.date.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 12),
            Text('Location: \\${event.location}'),
            const SizedBox(height: 12),
            Text('Price: \\${event.ticketPrice} RWF'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _simulatePaymentAndBookTicket,
              child: _loading ? const CircularProgressIndicator() : const Text('Book Ticket'),
            ),
            if (_successMessage != null) ...[
              const SizedBox(height: 24),
              Text(_successMessage!, style: const TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }
} 