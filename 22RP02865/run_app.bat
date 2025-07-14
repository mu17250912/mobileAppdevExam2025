@echo off
echo StudyMate App - Launch Script
echo =============================
echo.
echo Choose your platform:
echo 1. Android Device
echo 2. Chrome (Web)
echo 3. Edge (Web)
echo 4. Windows Desktop
echo 5. Clean and rebuild
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo Launching on Android device...
    flutter run -d 08316352C8003580
) else if "%choice%"=="2" (
    echo Launching on Chrome...
    flutter run -d chrome
) else if "%choice%"=="3" (
    echo Launching on Edge...
    flutter run -d edge
) else if "%choice%"=="4" (
    echo Launching on Windows Desktop...
    flutter run -d windows
) else if "%choice%"=="5" (
    echo Cleaning and rebuilding...
    flutter clean
    flutter pub get
    echo Rebuild complete! Run the script again to launch.
) else (
    echo Invalid choice. Please run the script again.
)

pause 