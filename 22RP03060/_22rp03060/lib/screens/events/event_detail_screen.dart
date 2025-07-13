import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final VoidCallback? onEventUpdated;

  const EventDetailScreen({super.key, required this.eventId, this.onEventUpdated});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  Future<void> _loadEvent() async {
    try {
      final eventProvider = context.read<EventProvider>();
      final event = await eventProvider.getEventById(widget.eventId);
      
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (_event != null && _isEventOrganizer())
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // TODO: Navigate to edit event
                    break;
                  case 'delete':
                    _showDeleteConfirmation();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Event'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Event', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found'))
              : _buildEventDetails(),
    );
  }

  Widget _buildEventDetails() {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final isParticipating = _event!.participants.contains(authProvider.firebaseUser?.uid);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (_event!.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_event!.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),

          const SizedBox(height: 24),

          // Event Title and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  _event!.title,
                  style: AppTheme.heading1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(_event!.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _event!.status.toUpperCase(),
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event Description
          Text(
            _event!.description,
            style: AppTheme.body1,
          ),

          const SizedBox(height: 24),

          // Event Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    _event!.location,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time,
                    'Date & Time',
                    DateFormat('EEEE, MMMM d, y • h:mm a').format(_event!.dateTime),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.people,
                    'Participants',
                    '${_event!.participants.length}/${_event!.maxParticipants}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.person,
                    'Organizer',
                    _event!.organizerName,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Categories
          if (_event!.categories.isNotEmpty) ...[
            Text(
              'Categories',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _event!.categories.map((category) {
                return Chip(
                  label: Text(category),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Participants List
          Text(
            'Participants',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: 8),
          Card(
            child: _event!.participants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No participants yet'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _event!.participants.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _event!.participants[index][0].toUpperCase(),
                          ),
                        ),
                        title: Text('Participant ${index + 1}'),
                        subtitle: Text(_event!.participants[index]),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Share event
                  },
                  child: const Text('Share'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _event!.isFull && !isParticipating
                      ? null
                      : () async {
                          if (authProvider.firebaseUser != null) {
                            if (isParticipating) {
                              await eventProvider.leaveEvent(
                                _event!.id,
                                authProvider.firebaseUser!.uid,
                              );
                            } else {
                              await eventProvider.joinEvent(
                                _event!.id,
                                authProvider.firebaseUser!.uid,
                              );
                            }
                                                            // Refresh the event data
                                await _loadEvent();
                                // Notify parent to refresh data
                                widget.onEventUpdated?.call();
                          }
                        },
                  child: Text(
                    _event!.isFull && !isParticipating
                        ? 'Event Full'
                        : isParticipating
                            ? 'Leave Event'
                            : 'Join Event',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption,
              ),
              Text(
                value,
                style: AppTheme.body1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return AppTheme.primaryColor;
      case 'ongoing':
        return AppTheme.secondaryColor;
      case 'completed':
        return AppTheme.textSecondary;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  bool _isEventOrganizer() {
    final authProvider = context.read<AuthProvider>();
    return _event!.organizerId == authProvider.firebaseUser?.uid;
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final eventProvider = context.read<EventProvider>();
              await eventProvider.deleteEvent(_event!.id);
              if (mounted) {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 