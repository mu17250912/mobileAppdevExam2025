@echo off
echo ========================================
echo StudyMate App - Enhanced Build Script
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo Error: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 3: Checking available devices...
flutter devices

echo.
echo Step 4: Attempting to build APK...
echo Trying debug build first...

flutter build apk --debug
if %errorlevel% equ 0 (
    echo.
    echo Debug build successful! Now building release APK...
    flutter build apk --release
    if %errorlevel% equ 0 (
        echo.
        echo Release APK build successful! Now building AAB...
        flutter build appbundle --release
        if %errorlevel% equ 0 (
            echo.
            echo ========================================
            echo BUILD COMPLETED SUCCESSFULLY!
            echo ========================================
            echo.
            echo Files created:
            echo - APK: build\app\outputs\flutter-apk\app-release.apk
            echo - AAB: build\app\outputs\bundle\release\app-release.aab
            echo.
            echo Please test the APK on your device before submission.
        ) else (
            echo Error: AAB build failed
        )
    ) else (
        echo Error: Release APK build failed
    )
) else (
    echo.
    echo Debug build failed. Trying alternative approach...
    echo.
    echo Attempting web build instead...
    flutter build web --release
    if %errorlevel% equ 0 (
        echo.
        echo Web build successful! Web files are in build\web\
        echo.
        echo Note: For exam submission, you need APK/AAB files.
        echo Please try the following manual steps:
        echo 1. Restart your computer
        echo 2. Open Android Studio
        echo 3. Let it download Gradle dependencies
        echo 4. Try building again
    ) else (
        echo Error: Web build also failed
    )
)

echo.
pause 