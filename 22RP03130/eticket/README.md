# eTicket Mobile Application

## Overview

eTicket is a mobile application for event management and ticketing. The app supports three types of users: **Admin**, **Organizer**, and **User**. Each role has specific privileges and access to different features within the app.

---

## Getting Started

1. **Clone or download the project to your local machine.**
2. **Install dependencies:**
   - Make sure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.
   - Run `flutter pub get` in the project root.
3. **Configure Firebase:**
   - The project is already set up with Firebase configuration files for Android and iOS.
4. **Run the app:**
   - Use `flutter run` to launch the app on your emulator or device.

---

## User Roles & Privileges

### 1. **Admin**
- **Login Credentials:**
  - **Email:** herveishimwe740@gmail.com
  - **Password:** Hervinho@123
- **Privileges:**
  - Register new organizers (create organizer accounts)
  - View commission dashboard

### 2. **Organizer**
- **Privileges:**
  - Create new events
  - View "My Events" (events they have created)
  - View all tickets for their events
- **How to become an organizer:**
  - The admin must register you as an organizer. Once registered, log in with your credentials.

### 3. **User**
- **Privileges:**
  - Browse available events
  - Book tickets for events
  - View "My Tickets" (tickets they have purchased)
- **How to become a user:**
  - Register using the app's registration form. After registration, log in with your credentials.

---

## App Flow

1. **Splash Screen:**
   - Shown briefly on app launch.
2. **Sign In / Register:**
   - Users can register as a new user or log in as a user, organizer, or admin.
3. **Role Selection:**
   - If a new user has no role, they are prompted to select one (admin, organizer, or user). Only the admin can create organizers.
4. **Dashboard:**
   - After login, users are directed to their respective dashboards based on their role.

---

## Features by Role

### Admin Dashboard
- Register new organizers
- View commission dashboard

### Organizer Dashboard
- Create new events
- View list of events they have created
- View all tickets for their events

### User Dashboard
- Browse all available events
- Book tickets for events
- View tickets they have purchased

---

## Notes
- **Security:** For demonstration, the admin credentials are hardcoded. In production, always secure sensitive credentials and use proper authentication and authorization.
- **Firestore Rules:** The current Firestore rules may be open for development. Update them before deploying to production.

---

## Support
For any issues or questions, please contact the project maintainer.
