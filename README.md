# 📚 RwandaRead

A Flutter-based reading application with subscription monetization, offering access to thousands of books with premium features.

## ✨ Features

### 📖 Core Features
- **Book Library**: Access thousands of books from multiple sources
- **Advanced Search**: Filter by language, category, and source
- **Reading Progress**: Track your reading across all books
- **Bookmarks**: Save and organize reading positions
- **Offline Reading**: Download books (Premium feature)

### 💎 Premium Features
- **Unlimited Downloads**: Download unlimited books for offline reading
- **Advanced Search**: Enhanced search capabilities
- **Priority Support**: Dedicated customer support
- **Exclusive Content**: Access to premium-only books
- **Ad-Free Experience**: Enjoy reading without ads

### 💳 Subscription Plans
- **Basic Monthly**: $4.99/month
- **Premium Monthly**: $9.99/month
- **Premium Yearly**: $59.99/year (40% savings)

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.8.1+)
- Firebase Project with Authentication & Firestore
- Google Books API Key

### Installation
```bash
# Clone repository
git clone https://github.com/yourusername/rwandaread.git
cd rwandaread

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build
```bash
# Generate APK
flutter build apk --release

# Generate App Bundle (Play Store)
flutter build appbundle --release
```

## 🛠️ Tech Stack

- **Frontend**: Flutter, Dart, Material Design
- **Backend**: Firebase (Auth, Firestore)
- **APIs**: Google Books, Open Library, Project Gutenberg
- **Storage**: Hive (local), Shared Preferences

## 📁 Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic
├── widgets/         # Reusable widgets
└── utils/           # Utility functions
```

## 🔧 Configuration

### Firebase Setup
1. Create Firebase project
2. Enable Authentication (Google Sign-In)
3. Enable Cloud Firestore
4. Add `google-services.json` to `android/app/`

### API Keys
Create `.env` file:
```env
GOOGLE_BOOKS_API_KEY=your_api_key
```

## 📱 Screens

- **Library**: Home dashboard with statistics
- **Search**: Advanced book search
- **Book Detail**: Book information and actions
- **Reader**: Full-featured book reader
- **Subscription**: Plan selection and purchase

## 🧪 Testing

```bash
# Unit tests
flutter test

# Manual testing checklist
- [ ] User registration/login
- [ ] Book search and filtering
- [ ] Reading progress tracking
- [ ] Subscription purchase flow
- [ ] Premium feature access
```

## 📦 Build Outputs

- **APK**: `build/app/outputs/flutter-apk/app-release.apk` (~51MB)
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (~44MB)

## 🐛 Troubleshooting

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Open Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/rwandaread/issues)
- **Email**: support@rwandaread.com

---

**Made with ❤️ for readers everywhere**
