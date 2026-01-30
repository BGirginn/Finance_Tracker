# Android Setup Notes

## Icon Files

The app launcher icons are not included in the repository. You need to add them:

1. **Using Flutter:**
   ```bash
   flutter create --platforms=android .
   ```
   This will generate default icons.

2. **Using Android Asset Studio:**
   - Go to https://romannurik.github.io/AndroidAssetStudio/
   - Generate icons
   - Place them in `android/app/src/main/res/mipmap-*/` folders

3. **Manually:**
   Create icon files in these locations:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

## Gradle Wrapper

The `gradle-wrapper.jar` file will be automatically downloaded by Gradle on first build. If you need to generate it manually:

```bash
cd android
./gradlew wrapper --gradle-version 8.3
```

## Local Properties

Create `android/local.properties` with your Android SDK path:

**macOS:**
```
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
```

**Linux:**
```
sdk.dir=/home/YOUR_USERNAME/Android/Sdk
```

**Windows:**
```
sdk.dir=C\:\\Users\\YOUR_USERNAME\\AppData\\Local\\Android\\Sdk
```

The setup script will try to create this automatically.
