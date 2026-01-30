# Quick Start Guide

## 🚀 Hızlı Başlangıç

### 1. İlk Kurulum

**macOS/Linux:**
```bash
./setup.sh
```

**Windows:**
```cmd
setup.bat
```

**Manuel Kurulum:**
```bash
# Flutter bağımlılıklarını yükle
flutter pub get

# Database kodunu oluştur
flutter pub run build_runner build --delete-conflicting-outputs

# iOS için (sadece macOS)
cd ios && pod install && cd ..
```

### 2. Android Studio'da Açma

1. **Android Studio'yu açın**
2. **File → Open**
3. `finance/android` klasörünü seçin
4. Gradle sync otomatik başlar
5. **Build → Make Project** ile build alın
6. **Run → Run 'app'** ile çalıştırın

**Alternatif (Terminal):**
```bash
flutter build apk          # APK oluştur
flutter build appbundle    # App Bundle oluştur
flutter run                # Çalıştır
```

### 3. Xcode'da Açma

1. **Terminal'de pods yükleyin:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Xcode'u açın**
3. **File → Open**
4. `ios/Runner.xcworkspace` dosyasını açın (⚠️ .xcodeproj DEĞİL!)
5. **Signing & Capabilities** sekmesinde development team seçin
6. **Product → Build** ile build alın
7. **Product → Run** ile çalıştırın

**Alternatif (Terminal):**
```bash
flutter build ios          # iOS build
flutter build ipa          # IPA oluştur
flutter run                # Çalıştır
```

## 📋 Gereksinimler

### Android
- ✅ Android Studio (latest)
- ✅ Android SDK (API 21+, önerilen: API 34)
- ✅ Java 8+
- ✅ Flutter SDK

### iOS (sadece macOS)
- ✅ Xcode (latest)
- ✅ CocoaPods (`sudo gem install cocoapods`)
- ✅ Flutter SDK
- ✅ Apple Developer hesabı (cihaz testi için)

## 🔧 Sorun Giderme

### Android Studio

**Gradle sync hatası:**
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
```

**SDK bulunamadı:**
- `android/local.properties` dosyasını oluşturun:
  ```
  sdk.dir=/path/to/your/android/sdk
  ```

### Xcode

**Pod install hatası:**
```bash
cd ios
pod deintegrate
pod install
cd ..
```

**Signing hatası:**
- Xcode → Runner → Signing & Capabilities
- Development team seçin
- Automatic signing'i aktif edin

**Build hatası:**
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

## 📱 Test Etme

### Emulator/Simulator

**Android:**
```bash
flutter emulators --launch <emulator_id>
flutter run
```

**iOS:**
```bash
open -a Simulator
flutter run
```

### Fiziksel Cihaz

**Android:**
- USB debugging'i açın
- `flutter devices` ile cihazı görün
- `flutter run` ile çalıştırın

**iOS:**
- Xcode'da cihazı seçin
- Signing ayarlarını yapın
- `flutter run` ile çalıştırın

## 🎯 Sonraki Adımlar

1. ✅ Projeyi build edin
2. ✅ Test cihazında çalıştırın
3. ✅ Özellikleri test edin
4. ✅ Release build alın

Detaylı bilgi için `BUILD_INSTRUCTIONS.md` dosyasına bakın.
