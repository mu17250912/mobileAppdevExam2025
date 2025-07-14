# Faith - Event Planning Platform

A smart mobile platform designed to simplify event planning and tracking for ceremonies (e.g., weddings, celebrations, faith-based events) in Rwanda. Faith connects event organizers with service providers through personalized dashboards, request handling, premium features, notifications, profile management, and payment processing.

## 🎯 Features

### For Event Organizers
- **Event Creation & Management**: Plan and organize events with detailed information
- **Service Provider Discovery**: Find photographers, dancers, artists, and ceremony preparators
- **Booking System**: Easy booking and coordination with service providers
- **Real-time Messaging**: Chat directly with service providers
- **Subscription Plans**: Access premium features with Basic, Premium, and Business plans
- **Event Tracking**: Monitor event progress and status
- **Payment Processing**: Secure payment handling for services and subscriptions
- **Notifications**: Real-time updates and reminders

### For Service Providers
- **Profile Management**: Create and manage professional profiles
- **Service Listings**: Showcase services and portfolios
- **Booking Management**: Handle incoming booking requests
- **Real-time Messaging**: Communicate directly with event organizers
- **Rating & Reviews**: Build reputation through client feedback
- **Premium Features**: Enhanced visibility and priority listing

### For Administrators
- **User Management**: Oversee all users and service providers
- **Event Monitoring**: Track all events and bookings
- **Analytics Dashboard**: Platform insights and statistics
- **Content Moderation**: Ensure quality and compliance

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter (Cross-platform mobile development)
- **Backend**: Firebase (Authentication, Firestore, Storage, Messaging)
- **State Management**: Provider + GetX
- **Local Storage**: Hive + SharedPreferences
- **UI/UX**: Material Design 3 with custom theme

### Project Structure
```
lib/
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
│   ├── auth/        # Authentication screens
│   ├── user/        # User dashboard screens
│   ├── admin/       # Admin dashboard screens
│   ├── messaging/   # Chat and messaging screens
│   └── subscription/ # Subscription management screens
├── services/         # Business logic services
├── utils/           # Constants and utilities
└── widgets/         # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd faith
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Configure Firebase project settings
   - Enable Authentication, Firestore, Storage, and Messaging

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Email/Password, Google Sign-in)
3. Set up Firestore database
4. Configure Storage for file uploads
5. Set up Cloud Messaging for notifications

### Android Configuration
The app includes proper Android configuration with:
- Firebase integration
- Google Services plugin
- Permission handling
- App signing setup

## 📱 User Types

### Event Organizers
- Create and manage events
- Browse and book service providers
- Chat with service providers
- Manage subscription plans
- Track event progress
- Handle payments and subscriptions

### Service Providers
- Professional profiles
- Service listings
- Booking management
- Real-time messaging with clients
- Portfolio showcase

### Administrators
- Platform oversight
- User management
- Analytics and reporting
- Content moderation

## 🎨 Design System

### Colors
- **Primary**: #6B46C1 (Purple)
- **Secondary**: #9F7AEA (Light Purple)
- **Background**: #F7FAFC (Light Gray)
- **Text**: #2D3748 (Dark Gray)

### Typography
- **Font Family**: Poppins
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

## 🔐 Security

- Firebase Authentication
- Secure data storage
- Input validation
- Permission-based access control

## 📊 Analytics

- User engagement tracking
- Event analytics
- Service provider performance
- Revenue tracking

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
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Email: support@faith.rw
- Phone: +250 789 123 456
- Website: https://faith.rw

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- The Rwandan event planning community
- All contributors and beta testers

---

**Faith** - Making event planning simple and beautiful in Rwanda 🇷🇼
