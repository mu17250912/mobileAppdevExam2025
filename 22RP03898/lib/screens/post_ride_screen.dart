import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../services/error_service.dart';
// import '../services/notification_service.dart';
// import '../services/booking_service.dart';
import '../services/analytics_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_message.dart';

class PostRideScreen extends StatefulWidget {
  final RideModel? editRide;

  const PostRideScreen({
    super.key,
    this.editRide,
  });

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen>
    with TickerProviderStateMixin {
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();
  final ErrorService _errorService = ErrorService();

  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _notesController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  bool _showPreview = false;

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  VehicleType _selectedVehicleType = VehicleType.bus;
  bool _isPremium = false;
  final List<String> _selectedAmenities = [];
  final Map<String, dynamic> _rules = {};

  // Location data
  double? _originLatitude;
  double? _originLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _availableAmenities = [
    'Air Conditioning',
    'WiFi',
    'USB Charging',
    'Luggage Space',
    'Wheelchair Accessible',
    'Child Seat Available',
    'Pet Friendly',
    'Entertainment System',
    'Refreshments',
    'Professional Driver',
    'GPS Tracking',
    'Insurance Coverage',
  ];

  final List<String> _availableRules = [
    'No Smoking',
    'No Food/Drinks',
    'Quiet Ride',
    'Mask Required',
    'Cash Only',
    'Pre-booking Required',
    'No Pets',
    'No Children Under 5',
    'Luggage Limit',
    'Arrive 10 Minutes Early',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadUserData();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.editRide != null) {
      final ride = widget.editRide!;
      _originController.text = ride.origin.name;
      _destinationController.text = ride.destination.name;
      _priceController.text = ride.price.toString();
      _seatsController.text = ride.totalSeats.toString();
      _descriptionController.text = ride.description ?? '';
      _vehicleNumberController.text = ride.vehicleNumber ?? '';
      _selectedDate = ride.departureTime;
      _selectedTime = TimeOfDay.fromDateTime(ride.departureTime);
      _selectedVehicleType = ride.vehicleType;
      _isPremium = ride.isPremium;
      _selectedAmenities.clear();
      _selectedAmenities.addAll(ride.amenities);
      _rules.clear();
      _rules.addAll(ride.rules);

      _originLatitude = ride.origin.latitude;
      _originLongitude = ride.origin.longitude;
      _destinationLatitude = ride.destination.latitude;
      _destinationLongitude = ride.destination.longitude;
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      _errorService.logError('Error loading user data', e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load user data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    _vehicleNumberController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editRide != null ? 'Edit Ride' : 'Post a Ride'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isSubmitting)
            IconButton(
              icon: Icon(_showPreview ? Icons.edit : Icons.preview),
              onPressed: () {
                setState(() {
                  _showPreview = !_showPreview;
                });
              },
              tooltip: _showPreview ? 'Edit Mode' : 'Preview Mode',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _error != null
                ? ErrorMessage(
                    error: _error,
                    onRetry: _loadUserData,
                  )
                : _showPreview
                    ? _buildRidePreview()
                    : _buildPostRideForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPostRideForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDriverInfoCard(),
            const SizedBox(height: 24),
            _buildBasicInfoCard(),
            const SizedBox(height: 24),
            _buildScheduleCard(),
            const SizedBox(height: 24),
            _buildVehicleCard(),
            const SizedBox(height: 24),
            _buildPricingCard(),
            const SizedBox(height: 24),
            _buildAmenitiesCard(),
            const SizedBox(height: 24),
            _buildRulesCard(),
            const SizedBox(height: 24),
            _buildPremiumCard(),
            const SizedBox(height: 24),
            _buildNotesCard(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRidePreview() {
    final previewRide = _buildPreviewRide();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade50,
                    Colors.deepPurple.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.preview,
                          color: Colors.deepPurple.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ride Preview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPreviewSection('Route',
                      '${_originController.text} → ${_destinationController.text}'),
                  _buildPreviewSection('Date & Time',
                      '${DateFormat('MMM dd, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}'),
                  _buildPreviewSection('Vehicle',
                      '${_selectedVehicleType.name.toUpperCase()} • ${_vehicleNumberController.text.isNotEmpty ? _vehicleNumberController.text : 'N/A'}'),
                  _buildPreviewSection('Price', '${_priceController.text} FRW'),
                  _buildPreviewSection(
                      'Seats', '${_seatsController.text} available'),
                  if (_isPremium)
                    _buildPreviewSection('Premium', 'Yes (Enhanced features)'),
                  if (_selectedAmenities.isNotEmpty)
                    _buildPreviewSection(
                        'Amenities', _selectedAmenities.join(', ')),
                  if (_rules.isNotEmpty)
                    _buildPreviewSection('Rules', _rules.keys.join(', ')),
                  if (_descriptionController.text.isNotEmpty)
                    _buildPreviewSection(
                        'Description', _descriptionController.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Post Ride',
            onPressed: _isSubmitting ? null : _submitRide,
            isLoading: _isSubmitting,
            backgroundColor: Colors.deepPurple.shade600,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: _currentUser?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _currentUser!.profileImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.blue.shade700,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.blue.shade700,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.name ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser?.vehicleType ?? 'Vehicle'} • ${_currentUser?.vehicleNumber ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                  if (_currentUser?.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentUser!.rating!.toStringAsFixed(1)} rating',
                          style: TextStyle(
                            color: Colors.amber.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Route Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _originController,
              labelText: 'Origin *',
              hintText: 'e.g., Nyagatare',
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter origin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _destinationController,
              labelText: 'Destination *',
              hintText: 'e.g., Rwamagana',
              prefixIcon: Icons.location_on_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter destination';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              hintText: 'Additional details about the ride',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.deepPurple.shade600,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(_selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.deepPurple.shade600,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vehicle Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VehicleType>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type *',
                border: OutlineInputBorder(),
              ),
              items: VehicleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getVehicleIcon(type)),
                      const SizedBox(width: 8),
                      Text(type.name.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _vehicleNumberController,
              labelText: 'Vehicle Number (Optional)',
              hintText: 'e.g., RAA 123A',
              prefixIcon: Icons.confirmation_number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pricing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    labelText: 'Price (FRW) *',
                    hintText: 'e.g., 5000',
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _seatsController,
                    labelText: 'Available Seats *',
                    hintText: 'e.g., 4',
                    prefixIcon: Icons.airline_seat_recline_normal,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of seats';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Seats must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Amenities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                  selectedColor: Colors.deepPurple.shade100,
                  checkmarkColor: Colors.deepPurple.shade700,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rule,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rules & Policies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableRules.map((rule) {
                final isSelected = _rules.containsKey(rule);
                return FilterChip(
                  label: Text(rule),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _rules[rule] = true;
                      } else {
                        _rules.remove(rule);
                      }
                    });
                  },
                  selectedColor: Colors.orange.shade100,
                  checkmarkColor: Colors.orange.shade700,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Premium Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Premium Ride'),
              subtitle: const Text('Enhanced features and priority listing'),
              value: _isPremium,
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                });
              },
              activeColor: Colors.amber.shade600,
            ),
            if (_isPremium) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Benefits:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Priority listing in search results\n'
                      '• Enhanced driver profile visibility\n'
                      '• Premium customer support\n'
                      '• Higher commission rates',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: Colors.deepPurple.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              labelText: 'Notes (Optional)',
              hintText: 'Any additional information for passengers',
              prefixIcon: Icons.edit_note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: widget.editRide != null ? 'Update Ride' : 'Post Ride',
          onPressed: _isSubmitting ? null : _submitRide,
          isLoading: _isSubmitting,
          backgroundColor: Colors.deepPurple.shade600,
          textColor: Colors.white,
        ),
        if (widget.editRide != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isSubmitting ? null : _deleteRide,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade600),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Delete Ride'),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
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

  Future<void> _selectTime(BuildContext context) async {
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

  Future<void> _submitRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (_currentUser == null) {
        throw Exception('User not authenticated');
      }

      final departureTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final origin = Location(
        name: _originController.text.trim(),
        latitude: _originLatitude ?? 0.0,
        longitude: _originLongitude ?? 0.0,
      );

      final destination = Location(
        name: _destinationController.text.trim(),
        latitude: _destinationLatitude ?? 0.0,
        longitude: _destinationLongitude ?? 0.0,
      );

      if (widget.editRide != null) {
        // Update existing ride
        final updatedRide = widget.editRide!.copyWith(
          origin: origin,
          destination: destination,
          departureTime: departureTime,
          vehicleType: _selectedVehicleType,
          vehicleNumber: _vehicleNumberController.text.trim(),
          totalSeats: int.parse(_seatsController.text),
          availableSeats: int.parse(_seatsController.text),
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          amenities: _selectedAmenities,
          rules: _rules,
          isPremium: _isPremium,
          notes: _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await _rideService.updateRide(widget.editRide!.id, updatedRide.toMap());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new ride
        final ride = await _rideService.createRide(
          origin: origin,
          destination: destination,
          departureTime: departureTime,
          vehicleType: _selectedVehicleType,
          vehicleNumber: _vehicleNumberController.text.trim(),
          totalSeats: int.parse(_seatsController.text),
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          amenities: _selectedAmenities,
          rules: _rules,
          isPremium: _isPremium,
        );

        // Log analytics
        try {
          await AnalyticsService().logEvent(
            'ride_created',
            parameters: {
              'ride_id': ride.id,
              'driver_id': _currentUser!.id,
              'vehicle_type': _selectedVehicleType.name,
              'is_premium': _isPremium.toString(),
              'price': double.parse(_priceController.text),
            },
          );
        } catch (e) {
          _errorService.logError('Analytics error', e);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      _errorService.logError('Error submitting ride', e);
      setState(() {
        _error = _errorService.getUserFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ride'),
        content: const Text(
            'Are you sure you want to delete this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _rideService.deleteRide(widget.editRide!.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _errorService.logError('Error deleting ride', e);
      setState(() {
        _error = _errorService.getUserFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  RideModel _buildPreviewRide() {
    final departureTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final origin = Location(
      name: _originController.text.trim(),
      latitude: _originLatitude ?? 0.0,
      longitude: _originLongitude ?? 0.0,
    );

    final destination = Location(
      name: _destinationController.text.trim(),
      latitude: _destinationLatitude ?? 0.0,
      longitude: _destinationLongitude ?? 0.0,
    );

    return RideModel(
      id: widget.editRide?.id ?? '',
      driverId: _currentUser?.id ?? '',
      driverName: _currentUser?.name ?? '',
      driverPhone: _currentUser?.phone,
      driverImage: _currentUser?.profileImage,
      driverRating: _currentUser?.rating,
      origin: origin,
      destination: destination,
      departureTime: departureTime,
      vehicleType: _selectedVehicleType,
      vehicleNumber: _vehicleNumberController.text.trim(),
      totalSeats: int.tryParse(_seatsController.text) ?? 0,
      availableSeats: int.tryParse(_seatsController.text) ?? 0,
      price: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text.trim(),
      amenities: _selectedAmenities,
      rules: _rules,
      isPremium: _isPremium,
      notes: _notesController.text.trim(),
      createdAt: widget.editRide?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  IconData _getVehicleIcon(VehicleType vehicleType) {
    switch (vehicleType) {
      case VehicleType.bus:
        return Icons.directions_bus;
      case VehicleType.minibus:
        return Icons.airport_shuttle;
      case VehicleType.moto:
        return Icons.motorcycle;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.truck:
        return Icons.local_shipping;
    }
  }

  String _getRideStatusDisplay(RideStatus status) {
    switch (status) {
      case RideStatus.scheduled:
        return 'Scheduled';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}
