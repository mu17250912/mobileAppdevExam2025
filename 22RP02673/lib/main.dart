import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/role_selection_screen.dart';
import 'presentation/driver/driver_register_screen.dart';
import 'presentation/home/home_map_screen.dart';
import 'presentation/driver/driver_profile_screen.dart';
import 'presentation/ride/ride_request_screen.dart';
import 'presentation/history/trip_history_screen.dart';
import 'presentation/profile/settings_screen.dart';
import 'presentation/driver/driver_dashboard_screen.dart';
import 'presentation/driver/driver_chat_screen.dart';
import 'presentation/driver/driver_trip_history_screen.dart';
import 'presentation/driver/driver_earnings_summary_screen.dart';
import 'presentation/driver/driver_profile_management_screen.dart';
import 'presentation/driver/driver_notifications_screen.dart';
import 'presentation/ride/passenger_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RwandaQuickRide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        DriverRegisterScreen.routeName: (context) => const DriverRegisterScreen(),
        HomeMapScreen.routeName: (context) => const HomeMapScreen(),
        DriverProfileScreen.routeName: (context) => const DriverProfileScreen(),
        RideRequestScreen.routeName: (context) => const RideRequestScreen(),
        TripHistoryScreen.routeName: (context) => const TripHistoryScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        DriverDashboardScreen.routeName: (context) => const DriverDashboardScreen(),
        '/driver_chat': (context) => const DriverChatScreen(),
        '/driver_trip_history': (context) => const DriverTripHistoryScreen(),
        '/driver_earnings_summary': (context) => const DriverEarningsSummaryScreen(),
        '/driver_profile_management': (context) => const DriverProfileManagementScreen(),
        '/driver_notifications': (context) => const DriverNotificationsScreen(),
        '/passenger_chat': (context) => const PassengerChatScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
