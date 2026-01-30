# Build Instructions

## Android Studio

### Prerequisites
- Android Studio (latest version)
- Android SDK (API 21+)
- Flutter SDK

### Steps

1. **Open Project**
   - Open Android Studio
   - Select "Open an existing project"
   - Navigate to the `finance` folder
   - Select the `android` folder

2. **Sync Gradle**
   - Android Studio will automatically sync Gradle
   - If not, click "Sync Now" when prompted
   - Wait for Gradle sync to complete

3. **Configure SDK**
   - Go to File → Project Structure
   - Ensure Android SDK is configured (API 34 recommended)
   - Set compileSdkVersion to 34

4. **Build**
   - Click Build → Make Project (or press Ctrl+F9 / Cmd+F9)
   - Or use: `flutter build apk` from terminal

5. **Run**
   - Connect an Android device or start an emulator
   - Click Run → Run 'app' (or press Shift+F10 / Ctrl+R)

### Troubleshooting
- If Gradle sync fails, try: `flutter clean` then `flutter pub get`
- Ensure `local.properties` exists with `sdk.dir` path
- Check that Java 8+ is installed

## Xcode

### Prerequisites
- Xcode (latest version)
- CocoaPods (`sudo gem install cocoapods`)
- Flutter SDK

### Steps

1. **Install Pods**
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Open in Xcode**
   - Open Xcode
   - File → Open
   - Navigate to `ios/Runner.xcworkspace` (NOT .xcodeproj)
   - Click Open

3. **Configure Signing**
   - Select "Runner" in the project navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Xcode will automatically create provisioning profile

4. **Select Device**
   - Choose a simulator or connected iOS device from the device selector

5. **Build**
   - Product → Build (or press Cmd+B)
   - Or use: `flutter build ios` from terminal

6. **Run**
   - Product → Run (or press Cmd+R)
   - Or use: `flutter run` from terminal

### Troubleshooting
- If pods fail to install: `pod deintegrate` then `pod install`
- If build fails, try: `flutter clean` then `flutter pub get`
- Ensure minimum iOS version is 12.0
- Check that CocoaPods is up to date: `pod --version`

## Flutter Commands

### Build for Android
```bash
flutter build apk          # APK file
flutter build appbundle   # App Bundle for Play Store
```

### Build for iOS
```bash
flutter build ios         # iOS build
flutter build ipa         # IPA file for App Store
```

### Run
```bash
flutter run               # Run on connected device/emulator
flutter run -d <device>   # Run on specific device
```

## Notes

- First build may take longer as dependencies are downloaded
- Ensure you have proper signing certificates for release builds
- For iOS, you need an Apple Developer account for device testing
- Background services require proper permissions in both platforms
