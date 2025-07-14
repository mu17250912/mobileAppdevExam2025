# Blood Donor App

A Flutter application for managing blood donations and connecting donors with collectors.

## Features

- **User Authentication**: Secure login and registration with Firebase Authentication
- **Role-based Access**: Separate dashboards for blood donors and collectors
- **Registration Validation**: Only registered users can access the application
- **Google Sign-in**: Support for Google authentication
- **Real-time Database**: Firestore integration for user data management

## Validation System

The app now includes a comprehensive validation system that prevents unregistered users from accessing the application:

### Login Validation
- Users must be registered before they can log in
- Clear error messages for unregistered users
- Password validation for registered users
- Google sign-in validation against registered accounts

### Registration Validation
- Prevents duplicate email registrations
- Password strength requirements (minimum 6 characters)
- Role selection (Donor or Collector)
- Google account registration validation

### Error Messages
- **Red**: User not registered - "User not registered. Please register first."
- **Orange**: Invalid password for registered user - "Invalid password. Please try again."
- **Green**: Successful registration - "Registration successful! Please login."

## Setup Instructions

### 1. Firebase Configuration

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password and Google Sign-in
3. Create a Firestore database
4. Download the configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

### 2. Dependencies

The app uses the following Firebase packages:
- `firebase_core`: Core Firebase functionality
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database services
- `google_sign_in`: Google authentication

### 3. Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## User Flow

1. **New User**: Must register first with email/password or Google account
2. **Existing User**: Can log in with registered credentials
3. **Unregistered User**: Will be rejected with clear error message
4. **Role-based Navigation**: Users are directed to appropriate dashboard based on their role

## Security Features

- Firebase Authentication for secure user management
- Firestore security rules for data protection
- Input validation and sanitization
- Proper error handling and user feedback
- Session management with secure logout

## Testing the Validation

1. Try to login with an unregistered email - you should see a red error message
2. Register a new account - you should see a green success message
3. Login with the registered account - you should be redirected to the appropriate dashboard
4. Try Google sign-in with an unregistered account - you should be rejected
5. Logout and verify you're returned to the login screen




