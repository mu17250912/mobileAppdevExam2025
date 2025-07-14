@echo off
REM Build the Flutter APK in release mode
flutter build apk --release

REM Check if the APK was generated
set APK_PATH=android\app\build\outputs\apk\release\app-release.apk
if exist %APK_PATH% (
    echo APK found. Copying to project root as smart_daily-release.apk...
    copy /Y %APK_PATH% smart_daily-release.apk
    echo Done! APK is now at smart_daily-release.apk
) else (
    echo APK not found! Build may have failed.
) 