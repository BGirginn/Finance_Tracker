# Build Checklist

## ✅ Pre-Build Checklist

### General
- [ ] Flutter SDK installed and in PATH
- [ ] `flutter doctor` shows no critical issues
- [ ] Dependencies installed: `flutter pub get`
- [ ] Database code generated: `flutter pub run build_runner build --delete-conflicting-outputs`

### Android
- [ ] Android Studio installed
- [ ] Android SDK installed (API 21+, recommended: API 34)
- [ ] Java 8+ installed
- [ ] `android/local.properties` exists with `sdk.dir` path
- [ ] Gradle wrapper is ready (will download on first build)
- [ ] Icon files added (see ANDROID_SETUP.md)

### iOS (macOS only)
- [ ] Xcode installed (latest version)
- [ ] CocoaPods installed: `sudo gem install cocoapods`
- [ ] Pods installed: `cd ios && pod install && cd ..`
- [ ] Apple Developer account (for device testing)
- [ ] Signing configured in Xcode

## 🔨 Build Steps

### Android Studio
1. [ ] Open `android` folder in Android Studio
2. [ ] Wait for Gradle sync to complete
3. [ ] Check for any sync errors
4. [ ] Build → Make Project (Ctrl+F9 / Cmd+F9)
5. [ ] Check build output for errors
6. [ ] Run → Run 'app' (Shift+F10 / Ctrl+R)

### Xcode
1. [ ] Run `cd ios && pod install && cd ..`
2. [ ] Open `ios/Runner.xcworkspace` in Xcode
3. [ ] Select Runner in project navigator
4. [ ] Configure Signing & Capabilities (select team)
5. [ ] Select target device/simulator
6. [ ] Product → Build (Cmd+B)
7. [ ] Check build output for errors
8. [ ] Product → Run (Cmd+R)

## 🧪 Post-Build Testing

- [ ] App launches successfully
- [ ] Database operations work
- [ ] UI screens load correctly
- [ ] Scheduled transactions work (if configured)
- [ ] Notifications work (if configured)
- [ ] Backup/restore works
- [ ] No crashes on basic operations

## 🐛 Troubleshooting

### Android Build Fails
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Check `android/local.properties` exists
- [ ] Verify Android SDK path is correct
- [ ] Check Gradle version compatibility
- [ ] Review build.gradle files for errors

### iOS Build Fails
- [ ] Run `flutter clean`
- [ ] Run `cd ios && pod deintegrate && pod install && cd ..`
- [ ] Check CocoaPods version: `pod --version`
- [ ] Verify Xcode version compatibility
- [ ] Check signing configuration
- [ ] Review Podfile for errors

### Runtime Errors
- [ ] Check Flutter logs: `flutter logs`
- [ ] Verify database initialization
- [ ] Check permissions (notifications, storage)
- [ ] Review error messages in console

## 📦 Release Build

### Android
- [ ] Update version in `pubspec.yaml`
- [ ] Configure signing for release
- [ ] Build: `flutter build appbundle`
- [ ] Test release build on device

### iOS
- [ ] Update version in `pubspec.yaml`
- [ ] Configure App Store signing
- [ ] Build: `flutter build ipa`
- [ ] Test release build on device
- [ ] Archive in Xcode for App Store submission
