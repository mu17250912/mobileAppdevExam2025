# Firebase Integration Setup Guide

This guide explains how to set up and use the Firebase integration for fetching and storing tasks in your StudyMate app.

## Overview

The app now has a robust Firebase integration that provides:

- **Real-time task synchronization** between devices
- **Offline support** with local caching
- **Automatic conflict resolution** for pending changes
- **Error handling** and retry mechanisms
- **Security rules** to protect user data

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `mobileapp-9db35` (or your preferred name)
4. Follow the setup wizard

### 2. Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable Email/Password authentication
4. Optionally enable Google Sign-in for better UX

### 3. Enable Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location close to your users

### 4. Configure Security Rules

1. In Firestore Database, go to "Rules" tab
2. Replace the default rules with the content from `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Tasks collection - users can only access their own tasks
    match /tasks/{userId} {
      // Users can only access their own task documents
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User tasks subcollection
      match /userTasks/{taskId} {
        // Users can only access their own tasks
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Study goals collection - users can only access their own goals
    match /study_goals/{userId} {
      // Users can only access their own goal documents
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User goals subcollection
      match /userGoals/{goalId} {
        // Users can only access their own goals
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // User profiles - users can only access their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click "Publish"

## Data Structure

The app uses the following Firestore structure:

```
/tasks/{userId}/userTasks/{taskId}
├── subject: string
├── notes: string
├── dateTime: timestamp
├── duration: number
└── isCompleted: boolean
```

## Features

### 1. Offline Support

- Tasks are cached locally using SharedPreferences
- App works offline with local data
- Changes are queued and synced when connection is restored

### 2. Real-time Sync

- Tasks are automatically synced with Firebase
- Manual sync button available in task list screen
- Background sync when app becomes active

### 3. Error Handling

- Network errors are handled gracefully
- Failed operations are retried automatically
- User-friendly error messages

### 4. Security

- User authentication required
- Users can only access their own data
- Secure Firestore rules prevent unauthorized access

## Usage

### Adding Tasks

```dart
final task = Task(
  subject: 'Study Math',
  notes: 'Complete chapter 5',
  dateTime: DateTime.now().add(Duration(hours: 2)),
  duration: 60,
  isCompleted: false,
);

await taskProvider.addTask(task);
```

### Updating Tasks

```dart
task.isCompleted = true;
await taskProvider.updateTask(task);
```

### Deleting Tasks

```dart
await taskProvider.deleteTask(task);
```

### Manual Sync

```dart
await taskProvider.syncWithFirebase();
```

### Checking Sync Status

```dart
if (taskProvider.hasSyncError) {
  print('Sync error: ${taskProvider.lastSyncError}');
}
```

## Testing

Run the Firebase integration test:

```bash
dart test_firebase_integration.dart
```

This will test:
- Firebase connectivity
- Authentication
- CRUD operations on tasks
- Error handling

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Ensure user is logged in
   - Check Firebase Authentication is enabled
   - Verify email/password are correct

2. **Permission Denied**
   - Check Firestore security rules
   - Ensure user is authenticated
   - Verify user ID matches document path

3. **Network Errors**
   - Check internet connection
   - Verify Firebase project configuration
   - Check API keys in `firebase_options.dart`

4. **Data Not Syncing**
   - Check if user is authenticated
   - Verify Firestore rules allow read/write
   - Check console for error messages

### Debug Mode

Enable debug logging by checking the console output. The app logs all Firebase operations with prefixes like:
- `TaskStorage: Loading tasks from Firebase`
- `TaskProvider: Sync failed`
- `TaskStorage: Error adding task to Firebase`

## Performance Optimization

1. **Caching**: Tasks are cached locally for 24 hours
2. **Background Sync**: Firebase operations run in background
3. **Optimistic Updates**: UI updates immediately, syncs in background
4. **Batch Operations**: Multiple changes are batched when possible

## Security Best Practices

1. **Authentication**: Always require user authentication
2. **Authorization**: Users can only access their own data
3. **Input Validation**: Validate all user inputs
4. **Error Handling**: Don't expose sensitive information in errors
5. **Regular Updates**: Keep Firebase SDK updated

## Monitoring

Monitor your Firebase usage in the Firebase Console:

1. **Firestore**: Check read/write operations
2. **Authentication**: Monitor user sign-ups and sign-ins
3. **Analytics**: Track app usage and performance
4. **Crashlytics**: Monitor app crashes and errors

## Support

If you encounter issues:

1. Check the console logs for error messages
2. Verify Firebase project configuration
3. Test with the provided test script
4. Check Firestore security rules
5. Ensure all dependencies are up to date 