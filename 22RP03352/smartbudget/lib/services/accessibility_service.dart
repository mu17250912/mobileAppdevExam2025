import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Screen reader announcements
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Semantic labels for common UI elements
  static String getSemanticLabel(String element, {String? context}) {
    switch (element) {
      case 'add_expense_button':
        return 'Add new expense button';
      case 'budget_progress':
        return 'Budget progress indicator';
      case 'expense_list':
        return 'List of expenses';
      case 'analytics_chart':
        return 'Analytics chart showing spending patterns';
      case 'premium_upgrade':
        return 'Upgrade to premium features';
      case 'settings_menu':
        return 'Settings menu';
      case 'navigation_drawer':
        return 'Navigation menu';
      case 'back_button':
        return 'Go back';
      case 'save_button':
        return 'Save changes';
      case 'delete_button':
        return 'Delete item';
      case 'edit_button':
        return 'Edit item';
      case 'filter_button':
        return 'Filter options';
      case 'search_field':
        return 'Search expenses';
      case 'category_selector':
        return 'Select expense category';
      case 'amount_input':
        return 'Enter expense amount';
      case 'date_picker':
        return 'Select date';
      case 'currency_selector':
        return 'Select currency';
      default:
        return context != null ? '$element in $context' : element;
    }
  }

  // Enhanced semantic labels for analytics
  static String getAnalyticsSemanticLabel(String chartType, Map<String, dynamic> data) {
    switch (chartType) {
      case 'pie_chart':
        final total = data['total'] ?? 0;
        final categories = data['categories'] ?? [];
        return 'Pie chart showing spending distribution. Total spent: \$${total.toStringAsFixed(2)}. Categories: ${categories.join(', ')}';
      
      case 'bar_chart':
        final period = data['period'] ?? 'month';
        final total = data['total'] ?? 0;
        return 'Bar chart showing spending over $period. Total: \$${total.toStringAsFixed(2)}';
      
      case 'line_chart':
        final trend = data['trend'] ?? 'stable';
        return 'Line chart showing spending trend. Trend is $trend';
      
      case 'budget_vs_actual':
        final budget = data['budget'] ?? 0;
        final actual = data['actual'] ?? 0;
        final percentage = budget > 0 ? ((actual / budget) * 100).toStringAsFixed(1) : '0';
        return 'Budget comparison chart. Budget: \$${budget.toStringAsFixed(2)}, Actual: \$${actual.toStringAsFixed(2)}. ${percentage}% of budget used';
      
      default:
        return 'Analytics chart';
    }
  }

  // Accessibility hints for interactive elements
  static String getAccessibilityHint(String action) {
    switch (action) {
      case 'add_expense':
        return 'Double tap to add a new expense';
      case 'edit_expense':
        return 'Double tap to edit this expense';
      case 'delete_expense':
        return 'Double tap to delete this expense';
      case 'view_analytics':
        return 'Double tap to view detailed analytics';
      case 'upgrade_premium':
        return 'Double tap to upgrade to premium features';
      case 'filter_expenses':
        return 'Double tap to filter expenses by category or date';
      case 'export_data':
        return 'Double tap to export your financial data';
      case 'set_budget':
        return 'Double tap to set your monthly budget';
      case 'view_reports':
        return 'Double tap to view detailed financial reports';
      default:
        return 'Double tap to interact';
    }
  }

  // Voice guidance for navigation
  static String getNavigationGuidance(String screen) {
    switch (screen) {
      case 'home':
        return 'Home screen. You can add expenses, view budget, and access analytics';
      case 'analytics':
        return 'Analytics screen. View spending patterns and financial insights';
      case 'budget':
        return 'Budget screen. Set and track your spending limits';
      case 'settings':
        return 'Settings screen. Configure app preferences and account settings';
      case 'premium':
        return 'Premium upgrade screen. Unlock advanced features';
      case 'add_expense':
        return 'Add expense screen. Enter expense details and category';
      default:
        return 'Screen loaded';
    }
  }

  // High contrast mode support
  static Color getAccessibleColor(Color baseColor, {bool isHighContrast = false}) {
    if (!isHighContrast) return baseColor;
    
    // Ensure sufficient contrast for accessibility
    final luminance = baseColor.computeLuminance();
    if (luminance > 0.5) {
      return baseColor.withOpacity(0.9);
    } else {
      return baseColor.withOpacity(0.8);
    }
  }

  // Large text support
  static TextStyle getAccessibleTextStyle(TextStyle baseStyle, {bool isLargeText = false}) {
    if (!isLargeText) return baseStyle;
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * 1.2 : 16.0,
      height: baseStyle.height != null ? baseStyle.height! * 1.1 : 1.2,
    );
  }

  // Focus management for keyboard navigation
  static FocusNode createAccessibleFocusNode(String identifier) {
    return FocusNode(
      debugLabel: identifier,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          // Announce when element receives focus
          debugPrint('Focus received: $identifier');
        }
      },
    );
  }
} 