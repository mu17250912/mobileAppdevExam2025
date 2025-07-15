@echo off
echo Building StudyMate App...

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Build APK
echo Building APK...
flutter build apk --debug

REM Create directory if it doesn't exist
if not exist "build\app\outputs\flutter-apk" mkdir "build\app\outputs\flutter-apk"

REM Copy APK to Flutter expected location
echo Copying APK to Flutter location...
copy "android\app\build\outputs\apk\debug\app-debug.apk" "build\app\outputs\flutter-apk\app-debug.apk"

REM Run the app
echo Running app on device...
flutter run -d 08316352C8003580

pause 