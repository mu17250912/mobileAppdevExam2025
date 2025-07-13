import 'package:flutter/material.dart';

class AppTheme {
  // Consistent gradient background colors
  static const List<Color> backgroundGradient = [
    Color(0xFF7C3AED), // Colors.deepPurple.shade400
    Color(0xFF5B21B6), // Colors.deepPurple.shade800
    Color(0xFF4C1D95), // Colors.purple.shade900
  ];

  // Background gradient decoration
  static BoxDecoration backgroundDecoration = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: backgroundGradient,
    ),
  );

  // Responsive design utilities
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
  }

  // Responsive sizing utilities
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 18.0,
    double desktop = 20.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsivePadding(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(20);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  static double getResponsiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isMobile(context)) return width * 0.9; // 90% of screen width
    if (isTablet(context)) return width * 0.7; // 70% of screen width
    return 400.0; // Fixed width for desktop
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 56.0;
    return 64.0;
  }

  static double getResponsiveInputHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 56.0;
    return 64.0;
  }

  // Responsive spacing utilities
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 16.0,
    double tablet = 20.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Scaffold with consistent background
  static Widget scaffoldWithBackground({
    required BuildContext context,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? drawer,
    Widget? floatingActionButton,
    bool? resizeToAvoidBottomInset,
  }) {
    return Scaffold(
      appBar: appBar,
      body: Container(decoration: backgroundDecoration, child: body),
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  // Card with consistent styling
  static Card createCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.all(16),
      elevation: elevation ?? 8,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // Responsive card with adaptive sizing
  static Widget createResponsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
  }) {
    return Card(
      margin: margin ?? EdgeInsets.all(getResponsivePadding(context)),
      elevation: elevation ?? 8,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? getResponsiveCardPadding(context),
        child: child,
      ),
    );
  }

  // Centered responsive card with better layout
  static Widget createCenteredResponsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getResponsiveCardWidth(context),
          minHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: IntrinsicHeight(
          child: Card(
            margin: margin ?? EdgeInsets.all(getResponsivePadding(context)),
            elevation: elevation ?? 8,
            color: color ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: padding ?? getResponsiveCardPadding(context),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // Responsive centered container
  static Widget createResponsiveCenteredContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: padding ?? EdgeInsets.all(getResponsivePadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? getResponsiveCardWidth(context),
              minHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
  }

  // Consistent text styles
  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ) ??
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white.withOpacity(0.9),
        ) ??
        const TextStyle(fontSize: 16, color: Colors.white);
  }

  static TextStyle bodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.8),
        ) ??
        const TextStyle(fontSize: 14, color: Colors.white);
  }

  // Responsive text styles
  static TextStyle responsiveTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(
        context,
        mobile: 24,
        tablet: 28,
        desktop: 32,
      ),
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }

  static TextStyle responsiveBodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(
        context,
        mobile: 14,
        tablet: 16,
        desktop: 18,
      ),
      color: Colors.black87,
    );
  }

  static TextStyle responsiveInputStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(
        context,
        mobile: 16,
        tablet: 18,
        desktop: 20,
      ),
      color: Colors.black,
    );
  }

  // Input decoration theme for high-contrast text fields
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    labelStyle: const TextStyle(color: Colors.white),
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    prefixIconColor: Colors.white,
    suffixIconColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    fillColor: Colors.white.withOpacity(0.08),
    filled: true,
  );

  // Responsive input decoration
  static InputDecoration responsiveInputDecoration({
    required BuildContext context,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 18,
          desktop: 20,
        ),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black54,
        fontSize: getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 18,
          desktop: 20,
        ),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: Colors.black,
              size: getResponsiveIconSize(context),
            )
          : null,
      suffixIcon: suffixIcon,
      contentPadding:
          contentPadding ??
          EdgeInsets.symmetric(
            horizontal: 16,
            vertical: getResponsiveInputHeight(context) / 4,
          ),
    );
  }

  // Responsive button style
  static ButtonStyle responsiveButtonStyle(
    BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.deepPurple,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: getResponsiveButtonHeight(context) / 4,
        horizontal: getResponsivePadding(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      minimumSize: Size(double.infinity, getResponsiveButtonHeight(context)),
    );
  }
}
