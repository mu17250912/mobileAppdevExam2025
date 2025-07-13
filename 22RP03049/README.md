# 🚌 NyabugogoRide - Smart Bus Booking App

A comprehensive Flutter-based bus ticket booking application designed for inter-district public transport in Rwanda. This app provides a modern, user-friendly interface for booking bus tickets with real-time seat availability, payment processing, and comprehensive admin management features.

## Firstly for login as admin use john@gmail.com with password : 123456789 ##

## 🌟 Features

### 👤 User Features
- **Beautiful Authentication**: Modern login/register screens with gradient design and smooth animations
- **Real-time Booking**: Instant bus ticket booking with live seat availability
- **E-Ticket System**: Digital tickets with QR codes for easy access
- **Booking Management**: View and manage all your bookings in one place
- **Notifications**: Real-time notifications for booking confirmations and updates
- **Premium Membership**: Upgrade to premium for unlimited bookings and priority support
- **Favorites**: Save your favorite routes for quick access
- **Feedback System**: Submit feedback and suggestions
- **Multi-language Support**: English, Kinyarwanda, and French
- **Dark Mode**: Toggle between light and dark themes
- **Profile Management**: Update personal information and preferences

### 🔧 Admin Features
- **Dashboard Analytics**: Comprehensive analytics with charts and statistics
- **Route Management**: Add, edit, and delete bus routes
- **Bus Management**: Manage bus fleets, schedules, and seat configurations
- **Booking Overview**: View and manage all user bookings
- **User Management**: Monitor and manage user accounts
- **Notification System**: Send notifications to users
- **Real-time Statistics**: Live booking and revenue statistics
- **Payment Tracking**: Monitor payment status and revenue

### 🎨 Design Features
- **Modern UI/UX**: Beautiful gradient design with smooth animations
- **Responsive Design**: Works seamlessly across all device sizes
- **Intuitive Navigation**: Easy-to-use navigation with drawer menu
- **Color Scheme**: Professional blue and yellow theme representing Rwanda's colors
- **Icon Integration**: Comprehensive icon usage for better user experience

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile app development
- **Dart**: Programming language
- **Material Design**: UI/UX framework

### Backend & Services
- **Firebase Authentication**: User authentication and management
- **Cloud Firestore**: NoSQL database for real-time data
- **Firebase Analytics**: User behavior tracking and analytics
- **Firebase Cloud Messaging**: Push notifications
- **Google Mobile Ads**: Ad integration (configured)

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: any
  firebase_core: any
  firebase_auth: any
  cloud_firestore: any
  firebase_analytics: any
  google_mobile_ads: any
  provider: ^6.1.1
  flutter_local_notifications: any
  flutterfire_cli: ^1.3.1
  fl_chart: ^0.66.0
```

## 📱 Screenshots

### Authentication
- Modern gradient login/register screens
- Smooth animations and transitions
- Password visibility toggle
- Error handling with styled messages

### User Dashboard
- Real-time booking statistics
- Quick access to recent bookings
- Premium membership upgrade
- Notification center with badges

### Booking Flow
- Route selection with distance and duration
- Bus selection with real-time availability
- Instant booking confirmation
- E-ticket generation with QR codes

### Admin Dashboard
- Comprehensive analytics with charts
- Route and bus management
- User management interface
- Real-time statistics

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd exam
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Authentication, Firestore, and Analytics
   - Download `google-services.json` for Android
   - Configure Firebase options in `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

The app is configured with the following Firebase services:

- **Project ID**: `rp03049-2f84b`
- **Authentication**: Email/password authentication
- **Firestore**: Real-time database for routes, buses, bookings, and users
- **Analytics**: User behavior tracking
- **Cloud Messaging**: Push notifications

## 📊 Database Structure

### Collections

#### Users
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "role": "user|admin",
  "plan": "free|premium",
  "createdAt": "timestamp"
}
```

#### Routes
```json
{
  "from": "Kigali",
  "to": "Musanze",
  "distanceKm": 94,
  "estimatedDuration": "2h 30m",
  "active": true
}
```

#### Buses
```json
{
  "plateNumber": "RAB123A",
  "company": "Volcano Express",
  "routeId": "route_id",
  "departureTime": "2024-06-10T08:00:00Z",
  "totalSeats": 30,
  "availableSeats": 29,
  "seats": [
    {"seatNumber": 1, "booked": false},
    {"seatNumber": 2, "booked": true, "userId": "user_id"}
  ]
}
```

#### Bookings
```json
{
  "userId": "user_id",
  "busId": "bus_id",
  "routeId": "route_id",
  "seatNumber": 2,
  "bookingTime": "timestamp",
  "status": "confirmed",
  "paymentStatus": "pending|paid",
  "ticketCode": "NYA-20240610-0001"
}
```

#### Notifications
```json
{
  "userId": "user_id",
  "title": "Booking Confirmed",
  "message": "Your booking is confirmed",
  "sentAt": "timestamp",
  "unread": true,
  "auto": true
}
```

## 🔐 Authentication & Authorization

### User Roles
- **User**: Regular users can book tickets, view bookings, and manage profile
- **Admin**: Administrators have access to all management features

### Admin Access
For testing and development purposes, you can create an admin user with the following credentials:
- **Email**: `admin@nyabugogoride.com`
- **Password**: `admin123456789`

To set up admin access:
1. Register a new user account
2. Manually update the user's role to `admin` in Firebase Firestore
3. Or contact the development team for admin access

### Security Features
- Firebase Authentication with email/password
- Role-based access control
- Secure data validation
- Real-time security rules

## 📈 Analytics & Tracking

The app includes comprehensive analytics tracking:

- **User Events**: Login, registration, booking creation
- **Business Events**: Payment processing, premium upgrades
- **Performance Metrics**: App usage, feature adoption
- **Custom Events**: Route popularity, bus utilization

## 🎯 Key Features Explained

### Real-time Booking System
- Instant seat availability updates
- Concurrent booking prevention
- Real-time confirmation notifications
- Automatic seat assignment

### E-Ticket System
- Digital ticket generation
- QR code integration
- Offline ticket access
- Ticket validation

### Premium Membership
- Unlimited bookings
- Priority support
- Exclusive offers
- Enhanced features

### Admin Analytics
- Booking trends analysis
- Revenue tracking
- User behavior insights
- Route popularity metrics

## 🚧 Development Status

### ✅ Completed Features
- User authentication and registration
- Route and bus management
- Real-time booking system
- E-ticket generation
- Admin dashboard
- Analytics and reporting
- Notification system
- Premium membership
- Multi-language support
- Modern UI/UX design

### 🔄 In Progress
- Payment gateway integration
- Advanced seat selection
- Offline mode support
- Push notifications
- Advanced analytics

### 📋 Planned Features
- Mobile money integration
- Route optimization
- Driver app integration
- Customer support chat
- Social media integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**NyabugogoRide Team**
- Email: support@nyabugogoride.com
- Website: https://nyabugogoride.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI components
- Rwanda transport authorities for inspiration

## 📞 Support

For support, email support@nyabugogoride.com or create an issue in the repository.

---

**Made with ❤️ for Rwanda's transportation system**
