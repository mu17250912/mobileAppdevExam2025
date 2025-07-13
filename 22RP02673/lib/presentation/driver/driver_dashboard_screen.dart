import 'package:flutter/material.dart';
import '../../core/trip_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../core/session_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DriverDashboardScreen extends StatefulWidget {
  static const String routeName = '/driver_dashboard';
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isOnline = true;
  DocumentSnapshot? _pendingRequest;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _showingPopup = false;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _listenForPendingRequests();
    _loadRewardedInterstitialAd();
  }

  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3537164234841259/5443205779',
      request: AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _adShown = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show the ad after the first build, but only once per dashboard visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_adShown && _rewardedInterstitialAd != null) {
        _rewardedInterstitialAd!.show(
          onUserEarnedReward: (ad, reward) {
            // Optionally grant reward
          },
        );
        _adShown = true;
        _rewardedInterstitialAd = null;
        _loadRewardedInterstitialAd();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _rewardedInterstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['available'] != null) {
        setState(() {
          _isOnline = data['available'] == true;
        });
      }
    }
  }

  Future<void> _setAvailability(bool available) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (available) {
        // Get location before setting online
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable location services to go online.')));
            return;
          }
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
              return;
            }
          }
          if (permission == LocationPermission.deniedForever) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied.')));
            return;
          }
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'available': true,
            'driverInfo.location': {'lat': pos.latitude, 'lng': pos.longitude},
          });
          setState(() {
            _isOnline = true;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
        }
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'available': false});
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  void _listenForPendingRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('rideRequests')
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_showingPopup) {
        _pendingRequest = snapshot.docs.first;
        _showRideRequestPopup(_pendingRequest!);
      }
    });
  }

  void _showRideRequestPopup(DocumentSnapshot requestDoc) {
    _showingPopup = true;
    _secondsLeft = 20;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        _countdownTimer?.cancel();
        TripManager.declineRideRequest(requestDoc.id);
        Navigator.of(context, rootNavigator: true).pop();
        _showingPopup = false;
      }
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final req = requestDoc.data() as Map<String, dynamic>;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('New Ride Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup: ${req['pickup']}'),
                  Text('Destination: ${req['dropoff']}'),
                  Text('Fare: RWF ${req['fare']}'),
                  Text('Passenger: ${req['passengerName'] ?? req['passengerId'] ?? ''}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('$_secondsLeft s', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    _countdownTimer?.cancel();
                    await TripManager.declineRideRequest(requestDoc.id);
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _showingPopup = false);
                  },
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _countdownTimer?.cancel();
                    await TripManager.acceptRideRequest(requestDoc.id, FirebaseAuth.instance.currentUser!.uid);
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _showingPopup = false);
                  },
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _countdownTimer?.cancel();
      _showingPopup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              SessionManager.clear();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/role_selection', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Online Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isOnline,
                        activeColor: Colors.green,
                        onChanged: (val) => _setAvailability(val),
                      ),
                      Text(_isOnline ? 'Online' : 'Offline', style: TextStyle(color: _isOnline ? Colors.green : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: TripManager.getDriverTrips(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Failed to load trips. Please try again later.', style: TextStyle(color: Colors.red)),
                        );
                      }
                      final trips = snapshot.data?.docs ?? [];
                      final earnings = trips.fold<double>(0, (sum, doc) => sum + (doc['fare'] ?? 0));
                      return Card(
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Earnings (This Session)', style: TextStyle(fontSize: 16)),
                              Text('RWF ${earnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver_earnings_summary');
                    },
                    icon: const Icon(Icons.attach_money),
                    label: const Text('Earnings Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver_profile_management');
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver_notifications');
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Trip History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: TripManager.getDriverTrips(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Failed to load trips. Please try again later.', style: TextStyle(color: Colors.red)),
                        );
                      }
                      final trips = snapshot.data?.docs ?? [];
                      if (trips.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No completed trips yet.', style: TextStyle(color: Colors.black54)),
                        );
                      }
                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: trips.map((doc) {
                          final trip = doc.data() as Map<String, dynamic>;
                          final tripId = doc.id;
                          final status = trip['status'] ?? 'pending';
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(trip['photo'] ?? ''),
                                    backgroundColor: Colors.green,
                                  ),
                                  title: Text('${trip['pickup']} → ${trip['dropoff']}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${trip['date']} at ${trip['time']}\nPassenger: ${trip['passengerName'] ?? trip['passengerId'] ?? ''}'),
                                      Text('Status: $status', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    'RWF ${trip['fare']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Trip Details'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('From: ${trip['pickup']}'),
                                          Text('To: ${trip['dropoff']}'),
                                          Text('Date: ${trip['date']}'),
                                          Text('Time: ${trip['time']}'),
                                          Text('Passenger: ${trip['passengerName'] ?? trip['passengerId'] ?? ''}'),
                                          Text('Car: ${trip['car']}'),
                                          Text('Fare: RWF ${trip['fare']}'),
                                          Text('Status: $status'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (status == 'accepted')
                                  ButtonBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => TripManager.markArrived(tripId),
                                        child: const Text('Mark Arrived'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final reason = await showDialog<String>(
                                            context: context,
                                            builder: (context) {
                                              final controller = TextEditingController();
                                              return AlertDialog(
                                                title: const Text('Cancel Trip'),
                                                content: TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(labelText: 'Reason for cancellation'),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Back'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, controller.text),
                                                    child: const Text('Cancel Trip'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (reason != null && reason.isNotEmpty) {
                                            await TripManager.cancelRide(tripId, reason);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                if (status == 'arrived')
                                  ButtonBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => TripManager.startRide(tripId),
                                        child: const Text('Start Ride'),
                                      ),
                                    ],
                                  ),
                                if (status == 'started')
                                  ButtonBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => TripManager.completeRide(tripId),
                                        child: const Text('End Ride'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('Ride Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rideRequests')
                        .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .where('status', whereIn: ['pending', 'accepted', 'arrived', 'started'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Failed to load ride requests. Please try again later.', style: TextStyle(color: Colors.red)),
                        );
                      }
                      final rideRequests = snapshot.data?.docs ?? [];
                      if (rideRequests.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No ride requests at the moment.', style: TextStyle(color: Colors.black54)),
                        );
                      }
                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: rideRequests.map((doc) {
                          final req = doc.data() as Map<String, dynamic>;
                          final reqId = doc.id;
                          final status = req['status'] ?? 'pending';
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(req['passengerName'] ?? req['passengerId'] ?? 'Passenger'),
                                  subtitle: Text('From: ${req['pickup']}\nTo: ${req['dropoff']}\nContact: ${req['passengerContact'] ?? ''}'),
                                  trailing: Text('RWF ${req['fare']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  isThreeLine: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                ),
                                if (status == 'pending')
                                  ButtonBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => TripManager.acceptRideRequest(reqId, FirebaseAuth.instance.currentUser!.uid),
                                        child: const Text('Accept'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => TripManager.declineRideRequest(reqId),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            MyBannerAdWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          final query = await FirebaseFirestore.instance
              .collection('rideRequests')
              .where('driverId', isEqualTo: user.uid)
              .where('status', whereIn: ['accepted', 'arrived', 'started'])
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          if (query.docs.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No active trip to chat about.')),
              );
            }
            return;
          }
          final trip = query.docs.first.data();
          final chatId = query.docs.first.id;
          final passengerName = trip['passengerName'] ?? 'Passenger';
          Navigator.pushNamed(
            context,
            '/driver_chat',
            arguments: {
              'chatId': chatId,
              'passengerName': passengerName,
            },
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text('Chat'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class MyBannerAdWidget extends StatefulWidget {
  const MyBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<MyBannerAdWidget> createState() => _MyBannerAdWidgetState();
}

class _MyBannerAdWidgetState extends State<MyBannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3537164234841259/3091255043',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
} 