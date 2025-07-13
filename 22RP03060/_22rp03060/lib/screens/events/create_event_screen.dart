import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/ads_service.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? event;
  final VoidCallback? onEventSaved;
  const CreateEventScreen({super.key, this.event, this.onEventSaved});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _maxParticipants = AppConstants.defaultMaxParticipants;
  bool _isPrivate = AppConstants.defaultIsPrivate;
  List<String> _selectedCategories = <String>[];
  bool get isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _selectedDate = event.dateTime;
      _selectedTime = TimeOfDay(hour: event.dateTime.hour, minute: event.dateTime.minute);
      _maxParticipants = event.maxParticipants;
      _isPrivate = event.isPrivate;
      _selectedCategories = List<String>.from(event.categories);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();

    // Premium logic: limit free users to 3 events (only for create)
    final isPremium = authProvider.userModel?.isPremium ?? false;
    final myEventsCount = eventProvider.myEvents.length;
    if (!isEdit && !isPremium && myEventsCount >= 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text('Free users can only create up to 3 events. Upgrade to premium for unlimited events.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (authProvider.firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create an event'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = Event(
      id: isEdit ? widget.event!.id : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      organizerId: authProvider.firebaseUser!.uid,
      organizerName: authProvider.userModel?.name ?? 'Unknown',
      dateTime: eventDateTime,
      location: _locationController.text.trim(),
      maxParticipants: _maxParticipants,
      categories: _selectedCategories,
      isPrivate: _isPrivate,
      createdAt: isEdit ? widget.event!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await eventProvider.updateEvent(event);
    } else {
      success = await eventProvider.createEvent(event);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Event updated successfully!' : AppConstants.successEventCreated),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      
      // Show interstitial ad for free users when creating events (not editing)
      if (!isEdit && !isPremium && !kIsWeb) {
        try {
          await AdsService().loadInterstitialAd();
          await AdsService().showInterstitialAd();
        } catch (e) {
          print('Error showing interstitial ad: $e');
        }
      }
      
      widget.onEventSaved?.call();
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? AppConstants.errorGeneric),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        actions: [
          Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              return TextButton(
                onPressed: eventProvider.isLoading ? null : _saveEvent,
                child: eventProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Changes'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title
              TextFormField(
                controller: _titleController,
                style: AppTheme.body1.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: AppConstants.placeholderEventTitle,
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  if (value.length > AppConstants.maxEventTitleLength) {
                    return 'Title must be less than ${AppConstants.maxEventTitleLength} characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Event Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: AppTheme.body1.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: AppConstants.placeholderEventDescription,
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event description';
                  }
                  if (value.length > AppConstants.maxEventDescriptionLength) {
                    return 'Description must be less than ${AppConstants.maxEventDescriptionLength} characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                style: AppTheme.body1.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: AppConstants.placeholderEventLocation,
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event location';
                  }
                  if (value.length > AppConstants.maxEventLocationLength) {
                    return 'Location must be less than ${AppConstants.maxEventLocationLength} characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Date and Time Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Time',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(_selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Max Participants
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum Participants',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxParticipants.toDouble(),
                              min: 1,
                              max: AppConstants.maxParticipants.toDouble(),
                              divisions: AppConstants.maxParticipants - 1,
                              label: _maxParticipants.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _maxParticipants = value.round();
                                });
                              },
                            ),
                          ),
                          Text(
                            _maxParticipants.toString(),
                            style: AppTheme.heading3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Categories
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.eventCategories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Setting
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private Event',
                              style: AppTheme.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Only invited users can see this event',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPrivate,
                        onChanged: (value) {
                          setState(() {
                            _isPrivate = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, child) {
                    return ElevatedButton(
                      onPressed: eventProvider.isLoading ? null : _saveEvent,
                      child: eventProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Event'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 