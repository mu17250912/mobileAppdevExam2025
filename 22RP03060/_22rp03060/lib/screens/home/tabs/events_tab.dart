import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/event_model.dart';
import '../../../utils/theme.dart';
import '../../../utils/constants.dart';
import '../../events/event_detail_screen.dart';

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Event> _getFilteredEvents(List<Event> events) {
    List<Event> filtered = events;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               event.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               event.categories.any((category) => 
                   category.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((event) {
        return event.categories.contains(_selectedCategory);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: EventSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppConstants.placeholderSearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      ...AppConstants.eventCategories,
                    ].map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Events List
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredEvents = _getFilteredEvents(eventProvider.allEvents);

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != 'All'
                              ? 'No events found matching your criteria'
                              : 'No events available',
                          style: AppTheme.body2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final isParticipating = event.participants.contains(authProvider.firebaseUser?.uid);

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
              // Event Header
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
                  if (event.isPrivate)
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: AppTheme.textLight,
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
              
              // Categories and Participants
              Row(
                children: [
                  // Categories
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: event.categories.take(2).map((category) {
                        return Chip(
                          label: Text(
                            category,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Participants Count
                  Text(
                    '${event.participants.length}/${event.maxParticipants}',
                    style: AppTheme.caption,
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: event.isFull && !isParticipating
                          ? null
                          : () async {
                              if (authProvider.firebaseUser != null) {
                                if (isParticipating) {
                                  await eventProvider.leaveEvent(
                                    event.id,
                                    authProvider.firebaseUser!.uid,
                                  );
                                } else {
                                  await eventProvider.joinEvent(
                                    event.id,
                                    authProvider.firebaseUser!.uid,
                                  );
                                }
                              }
                            },
                      child: Text(
                        event.isFull && !isParticipating
                            ? 'Full'
                            : isParticipating
                                ? 'Leave'
                                : 'Join',
                      ),
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

class EventSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        final filteredEvents = eventProvider.searchEvents(query);

        if (filteredEvents.isEmpty) {
          return const Center(
            child: Text('No events found'),
          );
        }

        return ListView.builder(
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return ListTile(
              title: Text(event.title),
              subtitle: Text(event.location),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(eventId: event.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 