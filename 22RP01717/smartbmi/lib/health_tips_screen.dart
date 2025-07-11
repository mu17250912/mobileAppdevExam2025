import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final List<String> _tips = [
    'Drink 8 glasses of water today!',
    'Take a 30-minute walk.',
    'Eat more vegetables and fruits.',
    'Avoid sugary drinks.',
    'Get at least 7 hours of sleep.',
    'Stretch for 5 minutes every morning.',
    'Limit processed foods.',
    'Practice mindful eating.',
    'Take the stairs instead of the elevator.',
    'Have a screen-free hour before bed.',
    'Eat a healthy breakfast every day.',
    'Include protein in every meal.',
    'Snack on nuts or fruit instead of chips.',
    'Plan your meals ahead of time.',
    'Take deep breaths to reduce stress.',
    'Wash your hands before eating.',
    'Stand up and move every hour.',
    'Limit your salt intake.',
    'Cook at home more often.',
    'Chew your food slowly and thoroughly.',
    'Keep a water bottle with you.',
    'Try a new healthy recipe this week.',
    'Go to bed at the same time each night.',
    'Spend time outdoors in natural light.',
    'Replace soda with water or herbal tea.',
    'Practice gratitude daily.',
    'Limit screen time before bed.',
    'Eat colorful fruits and vegetables.',
    'Take a break and stretch during work.',
    'Share a healthy meal with a friend.'
  ];
  String _tipOfTheDay = '';
  List<String> _randomTips = [];
  bool _dailyReminder = false;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _refreshTips();
    _initNotifications();
    _loadReminderPref();
    _loadReminderTime();
  }

  void _refreshTips() {
    final random = Random();
    _tipOfTheDay = _tips[random.nextInt(_tips.length)];
    _randomTips = List<String>.from(_tips)..shuffle(random);
    _randomTips = _randomTips.take(5).toList();
    setState(() {});
  }

  Future<void> _loadReminderPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('daily_reminder') ?? false;
    });
    if (_dailyReminder) {
      _scheduleDailyNotification();
    }
  }

  Future<void> _saveReminderPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder', value);
  }

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 8;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    setState(() {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _saveReminderTime(picked);
      if (_dailyReminder) {
        await _scheduleDailyNotification();
      }
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    final InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifications.initialize(initSettings);
  }

  Future<void> _scheduleDailyNotification() async {
    final random = Random();
    final tip = _tips[random.nextInt(_tips.length)];
    await _notifications.zonedSchedule(
      0,
      'Health Tip',
      tip,
      _nextInstanceOfTime(_reminderTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily motivational health tips',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay tod) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, tod.hour, tod.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _cancelDailyNotification() async {
    await _notifications.cancel(0);
  }

  void _onReminderToggle(bool value) async {
    setState(() => _dailyReminder = value);
    await _saveReminderPref(value);
    if (value) {
      await _scheduleDailyNotification();
    } else {
      await _cancelDailyNotification();
    }
  }

  Widget _bmiExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What your BMI means', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _bmiRow('< 18.5', 'Underweight', Colors.blue),
        _bmiRow('18.5 – 24.9', 'Normal weight', Colors.green),
        _bmiRow('25 – 29.9', 'Overweight', Colors.orange),
        _bmiRow('30+', 'Obese', Colors.red),
      ],
    );
  }

  Widget _bmiRow(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(range, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.montserrat()),
        ],
      ),
    );
  }

  Widget _premiumTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.lock, color: Colors.grey),
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.grey)),
      subtitle: Text(subtitle, style: GoogleFonts.montserrat(color: Colors.grey)),
      enabled: false,
      tileColor: Colors.grey.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Tips', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Free Features', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5676EA))),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Color(0xFF5676EA)),
                        const SizedBox(width: 8),
                        Text('Tip of the Day', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_tipOfTheDay, style: GoogleFonts.montserrat(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list, color: Color(0xFF5676EA)),
                        const SizedBox(width: 8),
                        Text('Basic Tips', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF5676EA)),
                          tooltip: 'Refresh Tips',
                          onPressed: _refreshTips,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._randomTips.map((tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF5676EA), size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(tip, style: GoogleFonts.montserrat(fontSize: 15))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Switch(
                    value: _dailyReminder,
                    onChanged: _onReminderToggle,
                    activeColor: const Color(0xFF5676EA),
                  ),
                  const SizedBox(width: 12),
                  Text('Daily Reminders', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _dailyReminder ? _pickTime : null,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      '${_reminderTime.format(context)}',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _dailyReminder ? const Color(0xFF5676EA) : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
                ),
                child: _bmiExplanation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 