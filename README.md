# Nyabugogo Ride 🚌

A smart bus ticket booking app for inter-district public transport in Rwanda. Built with Flutter and Firebase, this application provides a seamless experience for both passengers and administrators to manage bus bookings efficiently.

## FIRSTLY TO LOGIN AS ADMIN USE EMAIL : john@gmail.com WITH PASSWORD : 123456789 ##

## 🌟 Features

### For Passengers
- **User Authentication**: Secure login and registration with Firebase Auth
- **Route Discovery**: Browse available bus routes with real-time information
- **Bus Selection**: View available buses with capacity and departure times
- **Seat Booking**: Interactive seat selection with real-time availability
- **Booking Management**: View and manage your current and past bookings
- **Favorites**: Save frequently used routes for quick access
- **Notifications**: Real-time updates on booking status and schedule changes
- **Profile Management**: Update personal information and preferences
- **Feedback System**: Rate and provide feedback for your journey
- **Multi-language Support**: English, Kinyarwanda, and French

### For Administrators
- **Admin Dashboard**: Comprehensive overview of system metrics
- **Route Management**: Add, edit, and manage bus routes
- **Bus Management**: Manage bus fleet with capacity and schedule details
- **Booking Analytics**: Detailed analytics and reporting
- **User Management**: Monitor and manage user accounts
- **Notification System**: Send announcements and updates to users
- **Booking Overview**: View and manage all bookings across the system

## 🛠️ Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Notifications**: Flutter Local Notifications
- **Charts**: FL Chart
- **State Management**: Provider

## 📱 Screenshots

*[Screenshots will be added here]*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.8.0)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nyabugogoride
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Analytics
   - Download `google-services.json` and place it in `android/app/`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # Main application entry point
├── auth_screens.dart         # Authentication screens (login/register)
├── firebase_options.dart     # Firebase configuration
└── screens/
    ├── role_gate.dart        # Role-based navigation
    ├── user_dashboard_screen.dart    # Main user dashboard
    ├── routes_screen.dart    # Route browsing
    ├── buses_screen.dart     # Bus selection
    ├── seat_selection_screen.dart    # Seat booking
    ├── my_bookings_screen.dart       # User bookings
    ├── favorites_screen.dart         # Saved routes
    ├── profile_screen.dart   # User profile
    ├── feedback_screen.dart  # Feedback system
    ├── user_notifications_screen.dart # User notifications
    └── admin/                # Admin-specific screens
        ├── admin_dashboard.dart      # Admin main dashboard
        ├── manage_routes_screen.dart # Route management
        ├── manage_buses_screen.dart  # Bus management
        ├── all_bookings_screen.dart  # All bookings overview
        ├── analytics_screen.dart     # Analytics and reports
        ├── user_management_screen.dart # User management
        └── notifications_screen.dart # Admin notifications
```

## 🔧 Configuration

### Firebase Configuration

1. **Authentication**: Enable Email/Password authentication
2. **Firestore Rules**: Configure security rules for your collections
3. **Storage Rules**: Set up storage rules for file uploads
4. **Analytics**: Enable Firebase Analytics for insights

### Environment Variables

Create a `.env` file in the root directory:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## 🎨 UI/UX Features

- **Material Design**: Modern and intuitive interface
- **Dark Mode**: Toggle between light and dark themes
- **Responsive Design**: Optimized for various screen sizes
- **Smooth Animations**: Enhanced user experience with animations
- **Accessibility**: Support for accessibility features

## 🔐 Security Features

- **Firebase Authentication**: Secure user authentication
- **Role-based Access**: Different interfaces for users and admins
- **Data Validation**: Input validation and sanitization
- **Secure Storage**: Encrypted local storage for sensitive data

## 📊 Analytics & Monitoring

- **Firebase Analytics**: Track user behavior and app performance
- **Crash Reporting**: Automatic crash detection and reporting
- **Performance Monitoring**: Monitor app performance metrics

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: [Your Name]
- **Student ID**: 22RP03049
- **Course**: Mobile Application Development

## 📞 Support

For support and questions:
- Email: [your-email@example.com]
- GitHub Issues: [Create an issue](https://github.com/yourusername/nyabugogoride/issues)

## 🔄 Version History

- **v1.0.0** - Initial release with core booking functionality
- **v1.1.0** - Added admin dashboard and analytics
- **v1.2.0** - Enhanced UI/UX and performance improvements

---

**Made with ❤️ for Rwanda's public transport system**
