# SafeRide Authentication Guide

## Overview
SafeRide uses Firebase Authentication for user management with Firestore for user profiles. This guide explains how to set up and test authentication.

## Test Users

### Pre-created Test Users
The following test users are available for testing:

#### Admin User
- **Email:** `admin@gmail.com`
- **Password:** `admin123`
- **Role:** Admin
- **Features:** Full admin access, user management, analytics

#### Passenger User
- **Email:** `passenger@gmail.com`
- **Password:** `passenger123`
- **Role:** Passenger
- **Features:** Book rides, view ride history, manage profile

#### Driver User
- **Email:** `driver@gmail.com`
- **Password:** `driver123`
- **Role:** Driver
- **Features:** Post rides, manage bookings, view earnings

## Creating Test Users

### Method 1: Using Admin Dashboard
1. Log in as admin user (`admin@gmail.com` / `admin123`)
2. Navigate to Admin Dashboard
3. Click "Create Test Users" button in Quick Actions
4. Wait for confirmation dialog

### Method 2: Manual Creation
If you need to create users manually, use the registration screen:
1. Go to Login Screen
2. Click "Don't have an account? Sign up"
3. Fill in the registration form
4. Select appropriate user type (Passenger/Driver)

## Troubleshooting

### Common Issues

#### 1. "User profile not found" Error
**Cause:** User exists in Firebase Auth but not in Firestore
**Solution:** 
- The app now automatically creates a basic profile for existing Auth users
- Use the "Fix User Roles" button in Admin Dashboard to normalize user data

#### 2. "Invalid credential" Error
**Cause:** Wrong email/password combination
**Solution:**
- Double-check email and password
- Use the test credentials provided above
- Reset password if needed using "Forgot Password" feature

#### 3. AnimationController Error
**Cause:** Animation being called after widget disposal
**Solution:** Fixed in latest version - animation checks for mounted state

### Firebase Setup Requirements

Ensure your Firebase project has:
1. **Authentication** enabled with Email/Password sign-in method
2. **Firestore Database** created with appropriate security rules
3. **Firebase configuration** properly set up in your app

### Security Rules Example
```javascript
// Firestore security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /rides/{rideId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## User Types and Permissions

### Passenger
- Book rides
- View ride history
- Rate drivers
- Manage profile
- Contact drivers

### Driver
- Post rides
- Accept/reject bookings
- View earnings
- Manage vehicle info
- View ratings

### Admin
- Manage all users
- Moderate content
- Verify payments
- View analytics
- Send notifications
- Create test users

## Development Notes

- User roles are stored in Firestore as strings: `'passenger'`, `'driver'`, `'admin'`
- The app automatically creates basic profiles for existing Auth users
- All authentication errors are logged for debugging
- Test users are created with default settings and can be customized

## Support

If you encounter authentication issues:
1. Check Firebase Console for any configuration issues
2. Verify Firestore security rules
3. Use the "Fix User Roles" feature in Admin Dashboard
4. Check the app logs for detailed error messages 