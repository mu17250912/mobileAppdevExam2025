@echo off
echo StudyMate Android Launcher
echo =========================
echo.
echo Choose an option:
echo 1. Run normally
echo 2. Run with no tree shake icons
echo 3. Run in release mode
echo 4. Clean and rebuild
echo 5. Check device connection
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo Running StudyMate on Android...
    flutter run -d 08316352C8003580
) else if "%choice%"=="2" (
    echo Running with no tree shake icons...
    flutter run -d 08316352C8003580 --no-tree-shake-icons
) else if "%choice%"=="3" (
    echo Running in release mode...
    flutter run -d 08316352C8003580 --release
) else if "%choice%"=="4" (
    echo Cleaning and rebuilding...
    flutter clean
    flutter pub get
    echo Rebuild complete! Run the script again to launch.
) else if "%choice%"=="5" (
    echo Checking device connection...
    flutter devices
) else (
    echo Invalid choice. Please run the script again.
)

pause 