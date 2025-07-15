# Authentication System Documentation

## Overview

The authentication system in this Flutter app uses Firebase Firestore to store user credentials and validate login attempts. The system includes several security features to protect user accounts, including **session destruction** to prevent back navigation after logout.

## Key Features

### 1. User Registration
- Validates email format and password strength
- Checks for existing accounts with the same email
- Hashes passwords before storing in Firebase
- Stores user data in Firestore collection 'users'

### 2. User Login
- Validates email format and password
- Checks credentials against Firebase database
- Implements rate limiting to prevent brute force attacks
- Provides detailed error messages for failed attempts

### 3. Security Features
- **Password Hashing**: Passwords are hashed using base64 encoding (for production, use bcrypt)
- **Rate Limiting**: Maximum 5 failed login attempts per email address
- **Account Lockout**: 15-minute lockout after 5 failed attempts
- **Input Validation**: Email format validation and password strength requirements
- **Case-Insensitive Email**: Email addresses are stored and compared in lowercase
- **Session Destruction**: Complete session destruction on logout prevents back navigation

### 4. Session Management
- **Local Storage**: User session data is stored locally using SharedPreferences
- **Session Destruction**: Complete session destruction prevents back navigation after logout
- **Auto-redirect**: Automatic redirection to login when session is destroyed
- **Navigation Stack Clearing**: Clears navigation stack to prevent back navigation

## How It Works

### Login Process
1. User enters email and password
2. System validates input format
3. Checks if account is locked due to previous failed attempts
4. Queries Firebase for user with matching email
5. Verifies password hash
6. Updates last login timestamp
7. Sets user as current user in UserService
8. Stores session data locally
9. Redirects to home screen

### Logout Process
1. User clicks logout
2. System destroys session completely
3. Clears local storage data
4. Sets session destroyed flag
5. Redirects to login page
6. Clears navigation stack to prevent back navigation

### Registration Process
1. User enters name, email, and password
2. System validates all inputs
3. Checks if email already exists
4. Hashes password
5. Creates new user document in Firebase
6. Sets user as current user
7. Stores session data locally
8. Redirects to login screen

## Session Destruction

The system implements complete session destruction to prevent users from accessing protected pages after logout:

### Features:
- **Complete Data Clearance**: All user data is removed from memory and local storage
- **Session Flag**: A session destroyed flag prevents any access to user data
- **Navigation Stack Clearing**: Uses `context.go()` to clear navigation history
- **Auto-redirect**: Automatically redirects to login when session is destroyed

### Implementation:
```dart
// Destroy session completely
UserService.destroySession();

// Redirect and clear navigation stack
context.go('/login');
```

## Error Handling

The system provides user-friendly error messages for various scenarios:

- **Invalid Email**: "Please enter a valid email address"
- **Account Not Found**: "No account found with that email address"
- **Wrong Password**: "Incorrect password. Please try again"
- **Rate Limited**: "Too many failed login attempts. Please try again in 15 minutes"
- **Network Errors**: "Network error. Please check your internet connection"
- **Session Expired**: "Session expired. Please log in again"

## Rate Limiting

- Maximum 5 failed login attempts per email
- 15-minute lockout period after 5 failed attempts
- Successful login resets the attempt counter
- Lockout time is displayed to users

## Files Structure

```
lib/
├── services/
│   ├── auth_service.dart      # Main authentication logic
│   ├── user_service.dart      # Current user management
│   └── session_manager.dart   # Session management
├── models/
│   └── user.dart             # User data model
├── features/auth/
│   ├── login_screen.dart     # Login UI
│   └── signup_screen.dart    # Registration UI
└── widgets/
    ├── auth_guard.dart       # Route protection
    └── auth_status_widget.dart # Authentication status display
```

## Usage Examples

### Protecting Routes
```dart
// Wrap any screen that requires authentication
SecureAuthGuard(
  child: HomeScreen(),
)
```

### Checking Login Status
```dart
if (UserService.isLoggedIn) {
  // User is logged in
  final user = UserService.currentUser;
  print('Welcome ${user?.name}');
}
```

### Logging Out with Session Destruction
```dart
final authService = AuthService();
await authService.signOut(); // This destroys the session completely
```

### Force Logout
```dart
SessionManager.forceLogout(context);
```

## Security Considerations

1. **Password Storage**: Currently uses simple base64 encoding. For production, implement proper hashing (bcrypt, Argon2)
2. **Rate Limiting**: Implemented in memory. For production, use persistent storage or server-side rate limiting
3. **Session Management**: Uses local storage with session destruction. Consider implementing secure token-based sessions
4. **Network Security**: Ensure all Firebase connections use HTTPS
5. **Input Sanitization**: All inputs are trimmed and validated before processing
6. **Session Destruction**: Complete session destruction prevents unauthorized access after logout

## Future Improvements

1. Implement proper password hashing (bcrypt)
2. Add email verification
3. Implement password reset functionality
4. Add biometric authentication
5. Implement secure token-based sessions
6. Add two-factor authentication
7. Implement server-side rate limiting
8. Add audit logging for security events
9. Add session timeout functionality
10. Implement secure token refresh mechanism

## Testing

To test the authentication system:

1. **Registration**: Create a new account with valid email and password
2. **Login**: Try logging in with correct credentials
3. **Invalid Login**: Try incorrect password to test rate limiting
4. **Lockout**: Attempt multiple failed logins to test account lockout
5. **Recovery**: Wait for lockout period to expire and try again
6. **Logout**: Test logout and verify back navigation is prevented
7. **Session Destruction**: Verify that session data is completely cleared

## Firebase Configuration

Ensure your Firebase project is properly configured:

1. Enable Firestore Database
2. Set up security rules for the 'users' collection
3. Configure authentication methods if using Firebase Auth
4. Set up proper indexes for email queries

## Security Rules Example

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
  }
}
```

## Dependencies

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences: ^2.2.2 # For local storage and session management
``` 