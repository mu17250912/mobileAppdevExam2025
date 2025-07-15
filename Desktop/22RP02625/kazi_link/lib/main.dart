import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1976D2),
  brightness: Brightness.light,
);
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1976D2),
  brightness: Brightness.dark,
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  textTheme: GoogleFonts.poppinsTextTheme(),
  scaffoldBackgroundColor: lightColorScheme.background,
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.primary,
    foregroundColor: lightColorScheme.onPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      color: lightColorScheme.onPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      elevation: 2,
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: lightColorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  iconTheme: IconThemeData(color: lightColorScheme.primary),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  scaffoldBackgroundColor: darkColorScheme.background,
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.surface,
    foregroundColor: darkColorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      color: darkColorScheme.onSurface,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      elevation: 2,
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: darkColorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  iconTheme: IconThemeData(color: darkColorScheme.primary),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const KaziLinkRoot());
}

class KaziLinkRoot extends StatelessWidget {
  const KaziLinkRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaziLink',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const KaziLinkApp(),
    );
  }
}
