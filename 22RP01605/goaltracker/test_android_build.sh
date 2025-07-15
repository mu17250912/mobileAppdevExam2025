#!/bin/bash

echo "🚀 GoalTracker Android Build Test Script"
echo "========================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter is installed"

# Check Flutter version
flutter --version

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any issues
echo "🔍 Checking for issues..."
flutter analyze

# Test on connected devices
echo "📱 Checking connected devices..."
flutter devices

# Build for Android
echo "🔨 Building Android APK..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "✅ Debug APK built successfully!"
    echo "📁 APK location: build/app/outputs/flutter-apk/app-debug.apk"
else
    echo "❌ Debug APK build failed!"
    exit 1
fi

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Release APK built successfully!"
    echo "📁 APK location: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Release APK build failed!"
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Check APK size
echo "📊 APK size information:"
ls -lh build/app/outputs/flutter-apk/

echo ""
echo "🎉 Android build test completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Install the APK on your Android device:"
echo "   adb install build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "2. Or transfer the APK to your device and install manually"
echo ""
echo "3. Test the app functionality on your Android phone"
echo ""
echo "🔧 Troubleshooting tips:"
echo "- Make sure your Android device has USB debugging enabled"
echo "- Ensure you have the latest Android SDK installed"
echo "- Check that all permissions are granted on the device"
echo "- Verify Firebase configuration is correct" 