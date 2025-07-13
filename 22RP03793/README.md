# TechBuy

TechBuy is a modern Flutter e-commerce app with real-time Firestore integration, supporting both buyers and sellers. It features dashboards, order management, demo payment flows, in-app ads, and premium upgrades.

## Features

### Buyer Side
- Browse products by category
- Add items to cart and place orders
- Demo payment flow (PayPal, MTN Mobile Money, Airtel Money)
- Order history and notifications
- See total commission paid
- In-app ads (with ad-free upgrade option)

### Seller Side
- Seller dashboard with stats (products, sales, orders, commission)
- Real-time order and payment notifications
- Confirm payments and manage products
- Premium seller subscription (monthly/annual)
- Commission tracking (5% per sale)

### Monetization
- Demo payment integration for buyers and sellers
- Premium upgrades (ad-free, seller premium)
- In-app ads (Google AdMob or demo ads)

## Setup Instructions

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd techbuy
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Firebase Setup:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
   - Ensure Firestore is enabled and security rules allow user access to their own data.

4. **AdMob Setup (Optional):**
   - Add your AdMob App ID and Ad Unit IDs in the appropriate places if using real ads.

5. **Run the app:**
   ```sh
   flutter run
   ```

## Development Notes
- The app uses Firestore for all data (users, products, orders, etc.).
- Demo payment flows are simulated; integrate real payment gateways as needed.
- In-app ads use a demo banner by default; swap in real AdMob widgets for production.
- Premium/ad-free status is tracked in the Firestore user document (`isPremium`, `isAdFree`).
- Seller commission is calculated and stored per order.

## Folder Structure
- `lib/` — Main app code (dashboards, services, screens)
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` — Platform-specific code
- `test/` — Widget tests

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](LICENSE)
