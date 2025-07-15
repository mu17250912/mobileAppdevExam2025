import 'package:flutter/material.dart';
import 'models/event.dart';
import 'services/event_service.dart';

// REMINDER: After testing with open Firestore rules, restore secure rules for production!
// See assistant's instructions for recommended secure rules for /events and /users.

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final String organizerId;
  const EventFormScreen({super.key, this.event, required this.organizerId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _premiumPriceController = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  bool _hasPremium = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _priceController.text = widget.event!.ticketPrice.toString();
      _date = widget.event!.date;
      _hasPremium = widget.event!.hasPremium;
      if (widget.event!.premiumTicketPrice != null) {
        _premiumPriceController.text = widget.event!.premiumTicketPrice.toString();
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || _date == null) return;
    setState(() => _loading = true);
    final event = Event(
      id: widget.event?.id ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: _date!,
      location: _locationController.text.trim(),
      organizerId: widget.organizerId,
      ticketPrice: double.parse(_priceController.text.trim()),
      hasPremium: _hasPremium,
      premiumTicketPrice: _hasPremium && _premiumPriceController.text.trim().isNotEmpty
        ? double.parse(_premiumPriceController.text.trim())
        : null,
    );
    try {
      await EventService().createEvent(event);
      setState(() => _loading = false);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? 'Create Event' : 'Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Ticket Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _hasPremium,
                onChanged: (v) {
                  setState(() => _hasPremium = v ?? false);
                },
                title: const Text('Enable Premium Ticket'),
              ),
              if (_hasPremium) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _premiumPriceController,
                  decoration: const InputDecoration(labelText: 'Premium Ticket Price'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (!_hasPremium) return null;
                    if (v == null || v.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                title: Text(_date == null ? 'Select Date' : _date!.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _saveEvent,
                child: _loading ? const CircularProgressIndicator() : const Text('Save Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 