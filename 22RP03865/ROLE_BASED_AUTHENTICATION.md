# Role-Based Authentication System

## Overview
The NeighborhoodAlert app implements a comprehensive role-based authentication system that differentiates between regular users and administrators.

## User Roles

### 1. User Role (`user`)
- **Default role** for all new registrations
- **Google Sign-In users** always get this role
- Can access user features: report alerts, view alerts, manage emergency contacts
- Navigates to `/home` after sign-in

### 2. Admin Role (`admin`)
- **Manually assigned** by existing admins
- Can access admin dashboard with full management capabilities
- Navigates to `/admin-dashboard` after sign-in

## Authentication Flow

### Manual Sign-Up/Sign-In
1. **Sign-Up**: Users register with email/password → Role: `user`
2. **Sign-In**: System checks user role in Firestore
   - If role = `admin` → Navigate to `/admin-dashboard`
   - If role = `user` → Navigate to `/home`

### Google Sign-In
1. **First-time Google Sign-In**: Creates new user with role: `user`
2. **Subsequent Google Sign-In**: Checks existing user role
3. **Always routes to `/home`** (Google users cannot be admins by default)

## Admin Management

### How to Make Someone an Admin
1. **Sign in as an existing admin**
2. **Go to Admin Dashboard** → Users tab
3. **Click "Manage User Roles"** button
4. **Find the user** you want to promote
5. **Click "Make Admin"** button

### Admin User Management Screen
- **Location**: `/admin-user-management`
- **Features**:
  - View all users with their roles
  - Promote users to admin role
  - See which users signed up via Google
  - Visual indicators for different roles

## Database Structure

### Users Collection
```json
{
  "name": "User Name",
  "email": "user@example.com",
  "phone": "+1234567890",
  "role": "user" | "admin",
  "passwordHash": "hashed_password", // Only for manual sign-ups
  "createdAt": "timestamp",
  "googleSignIn": true | false,
  "status": "active" | "pending" | "inactive"
}
```

## Security Features

### Role Validation
- **Client-side**: Routes users based on their role
- **Server-side**: Firestore security rules should validate roles
- **Manual admin assignment**: Only existing admins can promote users

### Google Sign-In Security
- **Automatic user creation**: New Google users get `user` role
- **No admin promotion**: Google users cannot be promoted to admin via the app
- **Manual override**: Admins can manually change roles in Firebase Console

## Implementation Details

### Key Files
- `lib/services/user_service.dart` - User management logic
- `lib/screens/sign_in_screen.dart` - Authentication with role checking
- `lib/screens/sign_up_screen.dart` - User registration
- `lib/screens/admin_user_management_screen.dart` - Admin role management
- `lib/screens/admin_dashboard_screen.dart` - Admin dashboard with user management

### UserService Methods
- `getUserByEmail()` - Retrieve user data
- `createUser()` - Create new user with specified role
- `getUserRole()` - Get user's role
- `handleGoogleSignIn()` - Handle Google authentication
- `getRouteForRole()` - Get appropriate route based on role
- `getWelcomeMessage()` - Get welcome message based on role

## Firebase Console Management

### Manual Role Changes
1. **Go to Firebase Console** → Firestore Database
2. **Navigate to `users` collection**
3. **Find the user document**
4. **Edit the `role` field** to `admin`
5. **Save changes**

### Security Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.token.email == resource.data.email || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## Testing the System

### Test Scenarios
1. **New user sign-up** → Should get `user` role → Navigate to `/home`
2. **Admin sign-in** → Should navigate to `/admin-dashboard`
3. **Google sign-in** → Should get `user` role → Navigate to `/home`
4. **Role promotion** → Admin promotes user → User becomes admin
5. **Manual Firebase role change** → User role changed in console → App respects new role

### Demo Admin Account
To test admin features:
1. Create a regular user account
2. Manually change their role to `admin` in Firebase Console
3. Sign in with that account
4. You should be redirected to the admin dashboard

## Notes
- **Google Sign-In users** are always assigned `user` role for security
- **Admin roles** must be manually assigned (either via app or Firebase Console)
- **Role changes** take effect immediately on next sign-in
- **Security** relies on proper Firestore security rules 