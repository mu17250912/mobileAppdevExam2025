@echo off
echo Building StudyMate App...
echo.

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building APK for release...
flutter build apk --release

echo Building AAB for Play Store...
flutter build appbundle --release

echo.
echo Build completed successfully!
echo.
echo APK location: build/app/outputs/flutter-apk/app-release.apk
echo AAB location: build/app/outputs/bundle/release/app-release.aab
echo.
echo Please compress these files into a ZIP file for submission.
pause 