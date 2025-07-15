# Deploy Firestore Indexes

To fix the database communication issues, you need to deploy the Firestore indexes.

## Method 1: Using Firebase Console (Recommended)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `saferide-65c14`
3. **Navigate to Firestore Database**
4. **Click on "Indexes" tab**
5. **Click "Add Index"** and create the following indexes:

### Bookings Collection Indexes:
- **Collection**: `bookings`
- **Fields**: 
  - `passengerId` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `bookings`
- **Fields**: 
  - `driverId` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `bookings`
- **Fields**: 
  - `status` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `bookings`
- **Fields**: 
  - `passengerId` (Ascending)
  - `status` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `bookings`
- **Fields**: 
  - `driverId` (Ascending)
  - `status` (Ascending)
  - `createdAt` (Descending)

### Rides Collection Indexes:
- **Collection**: `rides`
- **Fields**: 
  - `driverId` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `rides`
- **Fields**: 
  - `status` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `rides`
- **Fields**: 
  - `departureLocation` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `rides`
- **Fields**: 
  - `destinationLocation` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `rides`
- **Fields**: 
  - `departureLocation` (Ascending)
  - `destinationLocation` (Ascending)
  - `createdAt` (Descending)

### Users Collection Indexes:
- **Collection**: `users`
- **Fields**: 
  - `userType` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `users`
- **Fields**: 
  - `userType` (Ascending)
  - `isVerified` (Ascending)
  - `createdAt` (Descending)

### Payments Collection Indexes:
- **Collection**: `payments`
- **Fields**: 
  - `userId` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `payments`
- **Fields**: 
  - `status` (Ascending)
  - `createdAt` (Descending)

### Notifications Collection Indexes:
- **Collection**: `notifications`
- **Fields**: 
  - `userId` (Ascending)
  - `createdAt` (Descending)

- **Collection**: `notifications`
- **Fields**: 
  - `userId` (Ascending)
  - `isRead` (Ascending)
  - `createdAt` (Descending)

### Chat Messages Collection Indexes:
- **Collection**: `chat_messages`
- **Fields**: 
  - `chatId` (Ascending)
  - `createdAt` (Ascending)

- **Collection**: `chat_messages`
- **Fields**: 
  - `senderId` (Ascending)
  - `createdAt` (Descending)

## Method 2: Using Firebase CLI

If you have Firebase CLI installed:

```bash
# Login to Firebase
firebase login

# Set the project
firebase use saferide-65c14

# Deploy indexes
firebase deploy --only firestore:indexes
```

## After Deploying Indexes

1. **Wait 5-10 minutes** for indexes to build
2. **Test the app** - booking history and communication should work
3. **All user functions** should now work properly

## What This Fixes

- ✅ Booking history loading
- ✅ User communication between passengers and drivers
- ✅ Ride searching and filtering
- ✅ Payment history
- ✅ Notifications
- ✅ Chat functionality
- ✅ Admin dashboard data loading

The indexes will take a few minutes to build, but once they're ready, all the database communication errors should be resolved. 