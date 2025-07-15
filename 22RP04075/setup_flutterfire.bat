@echo off
echo Step 1: Activating flutterfire_cli globally
dart pub global activate flutterfire_cli

echo Step 2: Navigating to your Flutter project
cd /d D:\ANDROID\studysync

echo Step 3: Adding flutterfire_cli to pubspec.yaml
flutter pub add flutterfire_cli

echo Step 4: Running FlutterFire configuration
dart run flutterfire_cli:flutterfire configure

pause
