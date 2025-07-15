import 'package:flutter/material.dart';
import '../../core/trip_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RideRequestScreen extends StatefulWidget {
  static const String routeName = '/ride_request';
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _isRequesting = false;
  bool _showConfirmation = false;
  String? _latestRequestId;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _requestRide() async {
    setState(() {
      _isRequesting = true;
    });
    // Fetch passenger info from Firestore
    final user = FirebaseAuth.instance.currentUser;
    String passengerName = '';
    String passengerContact = '';
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        passengerName = data['name'] ?? user.displayName ?? user.email ?? '';
        passengerContact = data['contact'] ?? user.email ?? '';
      } else {
        passengerName = user.displayName ?? user.email ?? '';
        passengerContact = user.email ?? '';
      }
    }
    if (passengerName.isEmpty || passengerContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile is incomplete. Please update your name and contact in settings.')),
      );
      setState(() => _isRequesting = false);
      return;
    }
    final docRef = await TripManager.addRideRequest({
      'pickup': _pickupController.text.trim(),
      'dropoff': _dropoffController.text.trim(),
      'fare': 2500,
      'passengerName': passengerName,
      'passengerContact': passengerContact,
    });
    setState(() {
      _isRequesting = false;
      _showConfirmation = true;
      _latestRequestId = docRef.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Ride'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _showConfirmation && _latestRequestId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('rideRequests').doc(_latestRequestId).snapshots(),
                builder: (context, snapshot) {
                  final status = snapshot.data?.get('status') ?? 'pending';
                  final driverId = snapshot.data?.get('driverId');
                  String message = 'Searching for Driver...';
                  Widget? driverInfoWidget;
                  if (status == 'accepted' && driverId != null) {
                    message = 'Driver accepted your request!';
                    driverInfoWidget = FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
                      builder: (context, driverSnap) {
                        if (!driverSnap.hasData) return const SizedBox.shrink();
                        final driver = driverSnap.data!.data() as Map<String, dynamic>?;
                        if (driver == null || driver['name'] == null || driver['driverInfo'] == null || driver['driverInfo']['carModel'] == null) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Driver profile incomplete.', style: TextStyle(color: Colors.red)),
                          );
                        }
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            Text('Driver: ${driver['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Car: ${driver['driverInfo']['carModel']}'),
                            Text('Contact: ${driver['contact'] ?? ''}'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final phone = driver['whatsapp'] ?? driver['contact'];
                                final url = 'https://wa.me/$phone';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open WhatsApp.')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text('Chat on WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  if (status == 'arrived') message = 'Driver has arrived!';
                  if (status == 'started') message = 'Your ride has started.';
                  if (status == 'completed') message = 'Ride completed! Thank you.';
                  if (status == 'cancelled') message = 'Ride was cancelled.';
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        status == 'completed'
                            ? Icons.check_circle
                            : status == 'cancelled'
                                ? Icons.cancel
                                : Icons.directions_car,
                        color: status == 'completed'
                            ? Colors.green
                            : status == 'cancelled'
                                ? Colors.red
                                : Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (driverInfoWidget != null) driverInfoWidget,
                      const SizedBox(height: 12),
                      if (status == 'completed' || status == 'cancelled')
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Back to Home'),
                        ),
                    ],
                  );
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      prefixIcon: Icon(Icons.my_location),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dropoffController,
                    decoration: const InputDecoration(
                      labelText: 'Drop-off Location',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.green.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Estimated Fare', style: TextStyle(fontSize: 16)),
                          Text('RWF 2,500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isRequesting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isRequesting ? null : _requestRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _isRequesting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Confirm Ride'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
} 