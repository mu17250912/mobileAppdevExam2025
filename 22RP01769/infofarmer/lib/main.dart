import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'screens/weather_screen.dart';
import 'screens/market_screen.dart';
import 'screens/tips_screen.dart';
import '../models/daily_forecast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'models/hourly_forecast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/price_entry.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/disease_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'InfoFarmer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({Key? key}) : super(key: key);

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    final initFutures = [
      Hive.initFlutter(),
      NotificationService.initialize(),
      SubscriptionService.initialize(),
    ];
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DailyForecastAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HourlyForecastAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserAdapter());
    initFutures.add(Hive.openBox<DailyForecast>('weather_history'));
    initFutures.add(Hive.openBox('subscriptions'));
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        initFutures.add(MobileAds.instance.initialize());
      }
    } catch (e) {
      print('Mobile ads not supported on this platform: \$e');
    }
    await Future.wait([
      Future.wait(initFutures),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    Timer(const Duration(seconds: 1), () => NotificationService.showLoginNotification());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        } else {
          return MyApp();
        }
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Removed: Locale _locale = const Locale('en');
  // Removed: void setLocale(Locale locale) { ... }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfoFarmer',
      debugShowCheckedModeBanner: false,
      // Removed: locale: _locale,
      // Removed: supportedLocales: [const Locale('en'), const Locale('rw')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // Removed: final void Function(Locale) onLocaleChange;
  // Removed: required this.onLocaleChange
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InfoFarmer'),
        // Removed: actions: [ ... language selection PopupMenuButton ... ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _HomeFeatureButton(
              icon: Icons.agriculture,
              label: 'Crop Tips',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
            _HomeFeatureButton(
              icon: Icons.bug_report,
              label: 'Pest Help',
              color: Colors.brown,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DiseaseScreen(username: 'admin')),
                );
              },
            ),
            _HomeFeatureButton(
              icon: Icons.cloud,
              label: 'Weather',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherScreen()),
                );
              },
            ),
            _HomeFeatureButton(
              icon: Icons.attach_money,
              label: 'Market Prices',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MarketScreen(isAdmin: false)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HomeFeatureButton({required this.icon, required this.label, required this.color, required this.onTap, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color, semanticLabel: label),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class MyForecastScreen extends StatelessWidget {
  final List<DailyForecast> forecasts;
  const MyForecastScreen({required this.forecasts, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forecasts')),
      body: ListView.builder(
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          final f = forecasts[index];
          return ListTile(
            leading: Icon(Icons.cloud),
            title: Text('${f.temp}°C on ${f.date.toLocal().toString().split(' ')[0]}'),
            subtitle: Text('Min: ${f.minTemp}, Max: ${f.maxTemp}, Rain: ${f.rainChance}, Wind: ${f.wind}'),
          );
        },
      ),
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showRainAlertNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'rain_alerts',
    'Rain Alerts',
    channelDescription: 'Notifications for rain, flood, and dry spell alerts',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: '',
  );
}

void checkForRainAlerts(List<HourlyForecast> hourly) {
  final heavyRain = hourly.where((h) => h.rain >= 10).toList();
  if (heavyRain.isNotEmpty) {
    showRainAlertNotification(
      'Heavy Rain Alert',
      'Heavy rain expected at ${heavyRain.first.time.hour}:00. Take precautions!'
    );
    return;
  }
  int consecutive = 0;
  for (final h in hourly) {
    if (h.rain >= 5) {
      consecutive++;
      if (consecutive >= 3) {
        showRainAlertNotification(
          'Flood Risk Alert',
          'Flood risk: 3+ hours of heavy rain expected. Stay safe!'
        );
        return;
      }
    } else {
      consecutive = 0;
    }
  }
  if (hourly.isNotEmpty && hourly.every((h) => h.rain == 0)) {
    showRainAlertNotification(
      'Dry Spell Alert',
      'No rain expected in the next 24 hours. Consider irrigation.'
    );
  }
}
