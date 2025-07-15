# Analytics & Tracking Documentation

## Overview

This document describes the comprehensive analytics and tracking system implemented in the Smart Daily Planner app. The system uses Firebase Analytics to track user behavior, revenue, and subscription metrics.

## Architecture

### Components

1. **AnalyticsService** (`lib/services/analytics_service.dart`)
   - Core analytics service that interfaces with Firebase Analytics
   - Handles all analytics events and user properties
   - Provides methods for tracking various user actions

2. **AnalyticsProvider** (`lib/providers/analytics_provider.dart`)
   - State management for analytics
   - Integrates with other providers to track events
   - Manages user context for analytics

3. **AnalyticsDashboardScreen** (`lib/screens/analytics_dashboard_screen.dart`)
   - UI for viewing analytics data
   - Displays metrics, charts, and insights
   - Provides export and refresh functionality

## Tracked Events

### User Events

#### Registration & Authentication
- `user_registration`: Tracks new user sign-ups
  - Parameters: `registration_method`, `user_id`, `user_email`, `timestamp`
- `user_login`: Tracks user logins
  - Parameters: `login_method`, `user_id`, `timestamp`

#### User Properties
- `user_email`: User's email address
- `user_type`: 'free' or 'premium'
- `is_premium`: Boolean indicating premium status
- `subscription_plan`: Current subscription plan

### Subscription Events

#### Revenue Tracking
- `subscription_started`: New subscription created
  - Parameters: `user_id`, `plan_id`, `amount`, `currency`, `payment_method`, `timestamp`
- `subscription_renewed`: Subscription renewal
  - Parameters: `user_id`, `plan_id`, `amount`, `currency`, `timestamp`
- `subscription_cancelled`: Subscription cancellation
  - Parameters: `user_id`, `plan_id`, `cancellation_reason`, `timestamp`
- `subscription_expired`: Subscription expiration
  - Parameters: `user_id`, `plan_id`, `timestamp`

#### Revenue Events
- `revenue_generated`: Revenue tracking
  - Parameters: `user_id`, `amount`, `currency`, `source`, `plan_id`, `transaction_id`, `timestamp`

### Feature Usage Events

#### Task Management
- `task_created`: New task creation
  - Parameters: `user_id`, `task_category`, `is_premium`, `timestamp`
- `task_completed`: Task completion
  - Parameters: `user_id`, `task_category`, `is_premium`, `timestamp`

#### Note Management
- `note_created`: New note creation
  - Parameters: `user_id`, `is_premium`, `timestamp`

#### Feature Usage
- `feature_used`: General feature usage
  - Parameters: `user_id`, `feature_name`, `additional_data`, `timestamp`

### Engagement Events

#### User Engagement
- `user_engagement`: User interaction tracking
  - Parameters: `user_id`, `action`, `screen_name`, `additional_data`, `timestamp`

#### Screen Views
- `screen_view`: Screen navigation tracking
  - Parameters: `screen_name`, `screen_class`

### Conversion Events
- `conversion`: Conversion tracking
  - Parameters: `user_id`, `conversion_type`, `source`, `value`, `currency`, `timestamp`

### Error & Performance Events
- `app_error`: Error tracking
  - Parameters: `user_id`, `error_type`, `error_message`, `screen_name`, `timestamp`
- `performance_metric`: Performance tracking
  - Parameters: `user_id`, `metric_name`, `value`, `unit`, `timestamp`

## Implementation Details

### Analytics Service Integration

The analytics service is integrated throughout the app:

1. **User Provider Integration**
   ```dart
   // Tracks user registration and login
   void _trackUserRegistration() {
     final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
     analyticsProvider.trackRegistration(method: 'email', userEmail: email);
   }
   ```

2. **Subscription Provider Integration**
   ```dart
   // Tracks subscription events and revenue
   void _trackSubscriptionStarted(String planId, double amount, String currency) {
     final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
     analyticsProvider.trackSubscriptionStarted(
       planId: planId,
       amount: amount,
       currency: currency,
     );
   }
   ```

3. **Task Provider Integration**
   ```dart
   // Tracks task creation
   void _trackTaskCreated(String category) {
     final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
     analyticsProvider.trackTaskCreated(taskCategory: category);
   }
   ```

### Analytics Dashboard

The analytics dashboard provides:

1. **User Metrics**
   - Total users
   - Active users
   - Premium users
   - Conversion rate

2. **Revenue Metrics**
   - Monthly revenue
   - Annual revenue
   - Average revenue per user
   - Churn rate

3. **Feature Usage**
   - Task creation usage
   - Note taking usage
   - Calendar sync usage
   - Data export usage

4. **Subscription Analytics**
   - Monthly vs annual subscriptions
   - Active vs expired subscriptions
   - Subscription trends

5. **User Engagement**
   - Daily/weekly/monthly active users
   - Session duration
   - Engagement trends

6. **Recent Events**
   - Real-time event tracking
   - Event timeline
   - Event details

## Revenue Tracking

### Subscription Revenue
- Tracks all subscription payments
- Monitors subscription lifecycle
- Calculates revenue metrics
- Tracks conversion rates

### Revenue Sources
1. **Monthly Subscriptions**: $9.99/month
2. **Annual Subscriptions**: $99.99/year (17% savings)
3. **Renewals**: Automatic tracking of subscription renewals
4. **Cancellations**: Tracking of subscription cancellations

### Revenue Metrics
- **Monthly Recurring Revenue (MRR)**
- **Annual Recurring Revenue (ARR)**
- **Average Revenue Per User (ARPU)**
- **Customer Lifetime Value (CLV)**
- **Churn Rate**

## User Behavior Tracking

### Feature Usage Analysis
- **Task Creation**: Tracks how often users create tasks
- **Note Taking**: Monitors note creation frequency
- **Calendar Usage**: Tracks calendar feature adoption
- **Premium Features**: Monitors usage of premium features

### User Journey Tracking
- **Onboarding**: Tracks user registration and first-time usage
- **Feature Adoption**: Monitors which features users adopt
- **Engagement Patterns**: Analyzes user engagement over time
- **Retention**: Tracks user retention and churn

### Conversion Funnel
1. **User Registration**: Track sign-up process
2. **Feature Usage**: Monitor initial feature adoption
3. **Premium Conversion**: Track free-to-premium conversion
4. **Subscription Renewal**: Monitor subscription retention

## Analytics Dashboard Features

### Real-time Metrics
- Live user count
- Real-time revenue tracking
- Active subscription monitoring
- Feature usage statistics

### Data Visualization
- **Charts**: Revenue trends, user growth, feature usage
- **Metrics Cards**: Key performance indicators
- **Event Timeline**: Recent user activities
- **Export Functionality**: Data export capabilities

### Custom Events
- **Custom Event Tracking**: Track any custom user action
- **Parameter Tracking**: Capture detailed event parameters
- **User Segmentation**: Segment users by behavior
- **A/B Testing Support**: Support for A/B testing analytics

## Privacy & Compliance

### Data Collection
- **User Consent**: Analytics collection with user consent
- **Data Minimization**: Only collect necessary data
- **Anonymization**: User data is anonymized where possible
- **GDPR Compliance**: Follows GDPR guidelines

### Data Security
- **Encryption**: All data is encrypted in transit
- **Access Control**: Limited access to analytics data
- **Data Retention**: Clear data retention policies
- **User Rights**: Users can request data deletion

## Firebase Analytics Configuration

### Setup
1. **Firebase Project**: Configured with analytics enabled
2. **Dependencies**: `firebase_analytics: ^11.5.2`
3. **Initialization**: Analytics initialized in main.dart
4. **User Properties**: Set user properties for segmentation

### Configuration
```dart
// Initialize analytics
await Firebase.initializeApp();
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

// Set user properties
await FirebaseAnalytics.instance.setUserId(id: userId);
await FirebaseAnalytics.instance.setUserProperty(name: 'user_type', value: 'premium');
```

## Usage Examples

### Tracking User Registration
```dart
// In UserProvider
void _trackUserRegistration() {
  final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
  analyticsProvider.trackRegistration(
    method: 'email',
    userEmail: userProfile.email,
  );
}
```

### Tracking Subscription Events
```dart
// In SubscriptionProvider
void _trackSubscriptionStarted(String planId, double amount) {
  final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
  analyticsProvider.trackSubscriptionStarted(
    planId: planId,
    amount: amount,
    currency: 'USD',
  );
}
```

### Tracking Feature Usage
```dart
// In TaskProvider
void _trackTaskCreated(String category) {
  final analyticsProvider = Provider.of<AnalyticsProvider>(this, listen: false);
  analyticsProvider.trackTaskCreated(taskCategory: category);
}
```

## Benefits

### Business Intelligence
- **Revenue Optimization**: Track revenue patterns and optimize pricing
- **User Insights**: Understand user behavior and preferences
- **Feature Performance**: Identify most/least used features
- **Conversion Optimization**: Improve conversion rates

### Product Development
- **Feature Prioritization**: Data-driven feature development
- **User Experience**: Identify pain points and improvements
- **Performance Monitoring**: Track app performance metrics
- **A/B Testing**: Support for feature testing

### Marketing & Growth
- **User Acquisition**: Track acquisition channels
- **Retention Analysis**: Understand user retention patterns
- **Revenue Growth**: Monitor revenue growth strategies
- **Customer Segmentation**: Segment users for targeted marketing

## Future Enhancements

### Advanced Analytics
- **Predictive Analytics**: Predict user behavior and churn
- **Machine Learning**: ML-powered insights and recommendations
- **Real-time Dashboards**: Live analytics dashboards
- **Advanced Segmentation**: More sophisticated user segmentation

### Integration Opportunities
- **Google Analytics**: Integration with Google Analytics
- **Marketing Tools**: Integration with marketing platforms
- **CRM Systems**: Integration with customer relationship management
- **Business Intelligence**: Integration with BI tools

## Conclusion

The analytics and tracking system provides comprehensive insights into user behavior, revenue patterns, and app performance. This data-driven approach enables informed decision-making for product development, marketing strategies, and business growth.

The system is designed to be scalable, privacy-compliant, and provides actionable insights for continuous improvement of the Smart Daily Planner app. 