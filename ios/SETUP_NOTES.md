# iOS Setup Notes

## First Time Setup

1. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

2. **Install Pods:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Open Workspace:**
   - Always open `Runner.xcworkspace` (NOT `.xcodeproj`)
   - This includes Flutter and Pod dependencies

## Signing & Capabilities

1. Open `Runner.xcworkspace` in Xcode
2. Select "Runner" in project navigator
3. Go to "Signing & Capabilities" tab
4. Select your development team
5. Xcode will automatically manage provisioning profiles

## Background Modes

The app uses background fetch for scheduled transactions. This is already configured in `Info.plist`:
- Background fetch
- Background processing

## Notifications

Notification permissions are configured. The app will request permission on first use.

## Minimum iOS Version

The app requires iOS 12.0 or later (configured in Podfile and project settings).
