# InfoFarmer

InfoFarmer is a mobile application built with Flutter to assist farmers with weather forecasts, market prices, agricultural tips, disease information, and more. integrates with various services to provide a comprehensive farming assistant.

## Features
- **Weather Forecasts:** View daily and hourly weather updates for your location.
- **Market Prices:** Check up-to-date market prices for agricultural products.
- **Agricultural Tips:** Access a library of farming tips and best practices.
- **Disease Information:** Identify and learn about crop diseases.
- **Notifications:** Receive timely notifications for weather, tips, and more.
- **In-App Purchases & Payments:** Supports PayPal, Stripe, and Flutterwave.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart 3.0.0 or higher
- Android Studio or Xcode (for mobile development)

### Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/mu17250912/mobileAppdevExam2025.git
   cd mobileAppdevExam2025/infofarmer
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

## Project Structure
- `lib/` - Main source code (screens, models, services, widgets)
- `assets/` - Images and data assets
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - Platform-specific code

## Dependencies
Key packages used:
- `google_sign_in`, `flutter_local_notifications`, `hive`, `http`, `geolocator`, `flutter_tts`, `flutter_svg`, `in_app_purchase`, `flutter_paypal`, `flutterwave_standard`, `flutter_stripe`, and more.

See `pubspec.yaml` for the full list.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](../LICENSE)
