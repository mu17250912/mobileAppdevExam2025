# Profile Data Fetching for All Accounts

This document describes the implementation of profile data fetching functionality for all user accounts in the E-Recruitment Flutter app.

## Overview

The app now includes comprehensive functionality to fetch and manage profile data for all user accounts. This includes:

- **UserService**: A centralized service for all user-related operations
- **AdminUsersScreen**: Admin interface to view and manage all user profiles
- **DashboardScreen**: Analytics dashboard showing user statistics
- **Enhanced Profile Management**: Improved profile fetching and management

## Features

### 1. UserService (`lib/services/user_service.dart`)

The `UserService` class provides the following methods for fetching profile data:

#### Core Methods:
- `getCurrentUserProfile()`: Fetch the current user's profile
- `getAllUserProfiles()`: Fetch all user profiles (admin only)
- `getUserProfileById(String userId)`: Fetch a specific user's profile
- `getUserProfilesWithPagination()`: Fetch users with pagination support
- `searchUsers(String searchTerm)`: Search users by name or email
- `getUserStatistics()`: Get user statistics and analytics
- `updateUserProfile()`: Update user profile data
- `deleteUserProfile()`: Delete a user profile

#### Usage Examples:

```dart
// Get current user profile
final userService = UserService();
final currentUser = await userService.getCurrentUserProfile();

// Get all user profiles (admin)
final allUsers = await userService.getAllUserProfiles();

// Search users
final searchResults = await userService.searchUsers('john');

// Get user statistics
final stats = await userService.getUserStatistics();
```

### 2. AdminUsersScreen (`lib/screens/admin_users_screen.dart`)

A comprehensive admin interface that provides:

#### Features:
- **User List**: Display all users with expandable cards
- **Search Functionality**: Search by name, email, or ID number
- **Filtering**: Filter users by CV, experience, degrees, or certificates
- **User Management**: View, edit, and delete user profiles
- **Detailed View**: Expandable cards showing full user information

#### User Card Information:
- Profile picture (CV URL or default icon)
- Name and email
- ID number
- Experience count
- Degree count
- Certificate count
- Full profile details in expandable sections

### 3. DashboardScreen (`lib/screens/dashboard_screen.dart`)

An analytics dashboard showing:

#### Statistics Cards:
- Total Users
- Users with CV
- Users with Experience
- Users with Degrees
- Users with Certificates

#### Quick Actions:
- View All Users
- Search Users
- User Analytics

### 4. Enhanced Profile Management

The existing `ProfileScreen` has been updated to use the `UserService` for:
- More reliable profile fetching
- Better error handling
- Consistent data structure

## Navigation

### Admin Access:
1. **Home Screen**: Admin users see additional buttons in the app bar
   - Dashboard icon: Navigate to analytics dashboard
   - Users icon: Navigate to all users management

2. **Dashboard Screen**: 
   - Statistics overview
   - Quick action buttons
   - Recent activity (placeholder)

3. **Admin Users Screen**:
   - Search and filter functionality
   - User management actions
   - Detailed user information

## Data Structure

### User Model (`lib/models/user.dart`):
```dart
class User {
  final String id;
  final String idNumber;
  final String fullName;
  final String telephone;
  final String email;
  final String password;
  String? cvUrl;
  List<Experience> experiences;
  List<String> degrees;
  List<String> certificates;
}
```

### Experience Model:
```dart
class Experience {
  final String? documentName;
  final String? documentPath;
  final Uint8List? documentBytes;
  final String description;
}
```

## Firebase Integration

The service integrates with Firebase Firestore using the following collections:
- `users`: Main user profiles collection
- Each user document contains all profile information including experiences, degrees, and certificates

## Security Considerations

- **Password Security**: Passwords are not included in profile fetching for security
- **Admin Access**: Admin features are only available to admin users
- **Error Handling**: Comprehensive error handling for all operations
- **Data Validation**: Input validation and sanitization

## Usage Examples

### For Developers:

1. **Fetch Current User Profile**:
```dart
final userService = UserService();
final profile = await userService.getCurrentUserProfile();
```

2. **Get All Users (Admin)**:
```dart
final allUsers = await userService.getAllUserProfiles();
```

3. **Search Users**:
```dart
final results = await userService.searchUsers('john@example.com');
```

4. **Get Statistics**:
```dart
final stats = await userService.getUserStatistics();
print('Total users: ${stats['totalUsers']}');
```

### For End Users:

1. **Admin Users**:
   - Access dashboard from home screen
   - View all user profiles
   - Search and filter users
   - Manage user accounts

2. **Regular Users**:
   - View and edit own profile
   - Add experiences, degrees, and certificates
   - Upload CV and documents

## Future Enhancements

1. **Real-time Updates**: Implement real-time listeners for live data updates
2. **Advanced Filtering**: Add more sophisticated filtering options
3. **Bulk Operations**: Support for bulk user management
4. **Export Functionality**: Export user data to CSV/PDF
5. **Advanced Analytics**: More detailed analytics and reporting
6. **User Activity Tracking**: Track user login and activity patterns

## Troubleshooting

### Common Issues:

1. **Profile Not Loading**:
   - Check Firebase connection
   - Verify user authentication
   - Check Firestore permissions

2. **Admin Access Not Working**:
   - Ensure user has admin privileges
   - Check route permissions

3. **Search Not Working**:
   - Verify search term format
   - Check Firestore indexes

### Error Messages:
- "Error fetching current user profile": Authentication or connection issue
- "Error loading users": Firestore permission or connection issue
- "Failed to load user profile": User document not found

## Dependencies

The implementation uses the following Flutter packages:
- `firebase_auth`: User authentication
- `cloud_firestore`: Database operations
- `firebase_storage`: File storage (for CVs and documents)
- `file_picker`: File selection for documents

## Testing

To test the functionality:

1. **Create Test Users**: Register multiple users with different profile data
2. **Test Admin Access**: Login as admin and verify dashboard access
3. **Test Search**: Use the search functionality with various terms
4. **Test Filtering**: Apply different filters and verify results
5. **Test User Management**: Try editing and deleting user profiles

## Conclusion

This implementation provides a comprehensive solution for fetching and managing profile data for all user accounts in the E-Recruitment app. The modular design allows for easy extension and maintenance, while the user-friendly interface ensures a smooth experience for both administrators and regular users. 