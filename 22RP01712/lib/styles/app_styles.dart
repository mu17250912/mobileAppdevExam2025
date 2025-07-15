import 'package:flutter/material.dart';

class AppStyles {
  // Color palette
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color primaryLight = Color(0xFF757DE8);
  static const Color primaryDark = Color(0xFF002984);
  static const Color accentColor = Color(0xFFFF5722);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  
  // Background colors
  static const Color backgroundPrimary = Color(0xFFF5F5F5);
  static const Color backgroundSecondary = Colors.white;
  static const Color backgroundTertiary = Color(0xFFFAFAFA);
  
  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFCCCCCC);
  static const Color borderDark = Color(0xFF999999);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  
  // Shadows
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
  
  static const List<BoxShadow> shadowHeavy = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  
  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle heading5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle heading6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textTertiary,
    height: 1.3,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textMuted,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // Button styles
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    textStyle: button,
  );
  
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    textStyle: button.copyWith(color: primaryColor),
  );
  
  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    textStyle: button.copyWith(color: primaryColor),
  );
  
  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowLight,
  );
  
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowMedium,
  );
  
  // Input styles
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: backgroundSecondary,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
      labelStyle: const TextStyle(
        color: textTertiary,
        fontSize: 16,
      ),
      hintStyle: const TextStyle(
        color: textMuted,
        fontSize: 16,
      ),
    );
  }
  
  // Container styles
  static Container primaryContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(spacingM),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      decoration: BoxDecoration(
        color: backgroundSecondary,
        borderRadius: BorderRadius.circular(borderRadius ?? radiusL),
        boxShadow: shadowLight,
      ),
      child: child,
    );
  }
  
  static Container secondaryContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(spacingM),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      decoration: BoxDecoration(
        color: backgroundTertiary,
        borderRadius: BorderRadius.circular(borderRadius ?? radiusL),
        border: Border.all(color: borderLight),
      ),
      child: child,
    );
  }
  
  // Spacing helpers
  static Widget verticalSpace(double height) => SizedBox(height: height);
  static Widget horizontalSpace(double width) => SizedBox(width: width);
  
  static Widget get verticalSpaceXS => verticalSpace(spacingXS);
  static Widget get verticalSpaceS => verticalSpace(spacingS);
  static Widget get verticalSpaceM => verticalSpace(spacingM);
  static Widget get verticalSpaceL => verticalSpace(spacingL);
  static Widget get verticalSpaceXL => verticalSpace(spacingXL);
  static Widget get verticalSpaceXXL => verticalSpace(spacingXXL);
  
  static Widget get horizontalSpaceXS => horizontalSpace(spacingXS);
  static Widget get horizontalSpaceS => horizontalSpace(spacingS);
  static Widget get horizontalSpaceM => horizontalSpace(spacingM);
  static Widget get horizontalSpaceL => horizontalSpace(spacingL);
  static Widget get horizontalSpaceXL => horizontalSpace(spacingXL);
  static Widget get horizontalSpaceXXL => horizontalSpace(spacingXXL);
  
  // Divider styles
  static Widget get divider => const Divider(
    color: borderLight,
    thickness: 1,
    height: 1,
  );
  
  static Widget get dividerThick => const Divider(
    color: borderMedium,
    thickness: 2,
    height: 2,
  );
  
  // Status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
      case 'success':
        return successColor;
      case 'pending':
      case 'waiting':
        return warningColor;
      case 'rejected':
      case 'error':
      case 'failed':
        return errorColor;
      case 'info':
      case 'processing':
        return infoColor;
      default:
        return textTertiary;
    }
  }
  
  // Gradient helpers
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradient => const LinearGradient(
    colors: [accentColor, Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} 