import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'routes/app_routes.dart';
import 'services/session_manager.dart';
import 'services/cart_service.dart';
import 'services/monetization_service.dart';

class UmusareApp extends StatelessWidget {
  const UmusareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Umusare',
            theme: themeProvider.theme,
            routerConfig: goRouter,
            builder: (context, child) {
              // Initialize session and cart when app starts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                SessionManager.initializeSession(context);
                // Load cart data from persistent storage
                CartService().loadCart();
                // Initialize monetization service
                MonetizationService().initialize();
              });
              return child!;
            },
          );
        },
      ),
    );
  }
} 