# UMUHINZI Smart

UMUHINZI Smart is a cross-platform Flutter application designed as an agricultural marketplace. It connects farmers and dealers, providing a modern, user-friendly platform for buying and selling agricultural products, accessing smart recommendations, and managing orders and payments.

## 🚀 Features
- Modern Material Design UI
- Secure authentication and role-based dashboards (Farmer & Dealer)
- Real-time product browsing, search, and filtering
- Shopping cart and order management
- Fertilizer recommendation
- Educational farming guides
- Simulated mobile money payment integration
- Push and local notifications
- Offline support and data caching
- Premium subscription and analytics dashboard
- Comprehensive error handling and analytics

## 📦 Project Structure
```
umuhinzismart/
├── android/           # Android platform code
├── ios/               # iOS platform code
├── lib/               # Main Flutter/Dart application code
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── services/          # Business logic
│   ├── widgets/           # Reusable UI components
│   └── main.dart          # App entry point
├── assets/            # Images, icons, animations
├── test/              # Automated tests
├── pubspec.yaml       # Flutter project config
└── README.md          # Project documentation
```

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- Firebase project (for authentication, Firestore, messaging, etc.)

### Setup
1. **Clone the repository:**
   ```sh
   git clone 
   cd umuhinzismart
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Firebase:**
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Update `lib/firebase_options.dart` if needed
4. **Run the app:**
   ```sh
   flutter run
   ```

## 💡 Usage
- Register as a farmer or dealer
- Browse and search for products
- Add products to your cart and proceed to payment
- Use demo phone numbers for simulated mobile money payments (e.g., +250785354935)
- Access premium features by upgrading your subscription


## 📝 License
This project is licensed under the MIT License.


