@echo off
REM Finance App Setup Script for Windows
REM This script prepares the project for building in Android Studio

echo Setting up Finance App...

REM Check Flutter installation
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Flutter is not installed. Please install Flutter first.
    exit /b 1
)

echo Flutter found
flutter --version | findstr /C:"Flutter"

REM Get Flutter dependencies
echo Installing Flutter dependencies...
flutter pub get

REM Generate database code
echo Generating database code...
flutter pub run build_runner build --delete-conflicting-outputs

REM Setup Android
echo Setting up Android...
if exist android (
    cd android
    
    REM Create local.properties if it doesn't exist
    if not exist local.properties (
        echo Creating local.properties...
        set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
        if exist "%SDK_PATH%" (
            echo sdk.dir=%SDK_PATH%> local.properties
            echo Created local.properties with SDK path: %SDK_PATH%
        ) else (
            echo Android SDK not found at %SDK_PATH%
            echo Please create android/local.properties manually with:
            echo sdk.dir=C:\path\to\your\android\sdk
        )
    )
    
    cd ..
)

REM Analyze code
echo Analyzing code...
flutter analyze

echo.
echo Setup complete!
echo.
echo To build for Android:
echo    - Open android\ folder in Android Studio
echo    - Or run: flutter build apk
echo.
echo To run the app:
echo    flutter run
