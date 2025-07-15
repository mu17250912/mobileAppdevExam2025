# TaskHub (Job Portal)


A modern Flutter-based job/task portal app where users can create, discover,  and complete tasks for rewards as well as growing their social media or publishing their channels. Built with Firebase for authentication and data storage. 
aims for people to get opportunity to make some free income by freelancing giving extra job activities to earn few bucks.

## Features

- **User Authentication**: Sign up, log in, and Google Sign-In using Firebase Auth.
- **Task Creation**: Users can create tasks specifying title, description, reward per click, and number of people. After submitting, users are prompted to pay to activate their task.
- **Admin Approval**: Tasks are saved as inactive (`is_active: false`) and only become visible to others after admin approval (manual activation in Firestore after payment confirmation).
- **Task Discovery**: Browse available tasks, view details, and track completion.
- **My Tasks**: Users can view tasks they have created and their approval status.
- **Cashout**: Users can request to withdraw their earnings to mobile money.
- **Notifications**: In-app notifications for important events.
- **Modern UI**: Clean, mobile-friendly design with improved padding, cards, and navigation.

## Monitization plan

*i will get revenues from user who paid for creating task(publishing their businesses, channels, referral task...)

*we will get  income from user who buys premium features to access high paying offers
*we will get income from withdrawal fee of 500RWF on each transaction.

_Add screenshots of the app here (optional)_

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio or VS Code

### Setup
1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd job_portal
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase Setup:**
   - Add your `google-services.json` to `android/app/` (already present for demo, replace with your own for production).
   - Make sure your Firebase project has the correct SHA-1 for release builds.
4. **Run the app:**
   ```bash
   flutter run
   ```
5. **Build APK:**
   ```bash
   flutter build apk
   ```

## Admin Approval Flow
- When a user creates a task, they are prompted to pay (instructions and phone number provided).
- The task is saved to Firestore with `is_active: false`.
- **Admin reviews payment** and sets `is_active: true` in the Firestore `tasks` collection to activate the task.

## Project Structure
- `lib/`
  - `main.dart` - App entry point and routing
  - `home_screen.dart` - Main navigation, dashboard, and drawer
  - `post_job_screen.dart` - Task creation and payment prompt
  - `login_screen.dart`, `register_screen.dart` - Authentication
  - `featured_tasks_screen.dart`, `task_details_screen.dart`, `job_details_screen.dart` - Task/job browsing
  - `firebase_options.dart` - Firebase config
- `assets/` - App and Google logos
- `android/app/google-services.json` - Firebase config

## Customization
- Update the payment phone number and admin name in `post_job_screen.dart` as needed.
- Adjust UI colors and branding in `main.dart` and `assets/`.

## Testing
- Basic widget test in `test/widget_test.dart`.

## License

MIT (or specify your license)
