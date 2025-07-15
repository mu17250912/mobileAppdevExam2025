import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/event_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/constants.dart';
import '../../events/event_detail_screen.dart';
import '../../events/create_event_screen.dart';

class MyEventsTab extends StatefulWidget {
  const MyEventsTab({super.key});

  @override
  State<MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<MyEventsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Organizing'),
            Tab(text: 'Participating'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrganizingEvents(),
          _buildParticipatingEvents(),
        ],
      ),
    );
  }

  Widget _buildOrganizingEvents() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (eventProvider.myEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t organized any events yet',
                  style: AppTheme.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first event to get started!',
                  style: AppTheme.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                  },
                  child: const Text('Create Event'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: eventProvider.myEvents.length,
          itemBuilder: (context, index) {
            final event = eventProvider.myEvents[index];
            return MyEventCard(
              event: event,
              isOrganizer: true,
            );
          },
        );
      },
    );
  }

  Widget _buildParticipatingEvents() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (eventProvider.participatingEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'re not participating in any events',
                  style: AppTheme.body2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse events to join one!',
                  style: AppTheme.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: eventProvider.participatingEvents.length,
          itemBuilder: (context, index) {
            final event = eventProvider.participatingEvents[index];
            return MyEventCard(
              event: event,
              isOrganizer: false,
            );
          },
        );
      },
    );
  }
}

class MyEventCard extends StatelessWidget {
  final Event event;
  final bool isOrganizer;

  const MyEventCard({
    super.key,
    required this.event,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final authProvider = context.read<AuthProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header with Status and Delete Icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTheme.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: AppTheme.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOrganizer)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Event',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await eventProvider.deleteEvent(event.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event deleted successfully!')),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Event Description
              Text(
                event.description,
                style: AppTheme.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Event Details
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(event.dateTime),
                    style: AppTheme.caption,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Participants Info
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participants.length}/${event.maxParticipants} participants',
                    style: AppTheme.caption,
                  ),
                  const Spacer(),
                  if (isOrganizer)
                    Text(
                      'Organizer',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(eventId: event.id),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isOrganizer)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateEventScreen(event: event),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (authProvider.firebaseUser != null) {
                            await eventProvider.leaveEvent(
                              event.id,
                              authProvider.firebaseUser!.uid,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Leave'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} from now';
    } else {
      return 'Starting now';
    }
  }
} 