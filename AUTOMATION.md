# 🤖 Automation Features

Bu proje artık tam otomatik! Aşağıdaki adımlar artık manuel yapılmasına gerek yok:

## ✅ Otomatik Yapılan İşlemler

### 1. Database Code Generation
**Önceden:** `flutter pub run build_runner build` manuel çalıştırılmalıydı
**Şimdi:** 
- ✅ Android Studio build öncesi otomatik çalışır (Gradle task)
- ✅ Xcode build öncesi otomatik çalışır (Pre-build script)
- ✅ `setup.sh` script'i ilk kurulumda çalıştırır

### 2. Android Launcher Icons
**Önceden:** Icon dosyaları manuel eklenmeliydi
**Şimdi:**
- ✅ `flutter_launcher_icons` paketi ile otomatik oluşturulur
- ✅ İlk build'de otomatik generate edilir
- ✅ `setup.sh` script'i ilk kurulumda oluşturur

### 3. iOS CocoaPods
**Önceden:** `pod install` manuel çalıştırılmalıydı
**Şimdi:**
- ✅ Xcode build öncesi otomatik kontrol edilir ve gerekirse install edilir
- ✅ `setup.sh` script'i ilk kurulumda çalıştırır
- ✅ Podfile değiştiğinde otomatik yeniden install edilir

### 4. Pre-build Checks
**Önceden:** Her build öncesi manuel kontrol gerekliydi
**Şimdi:**
- ✅ `scripts/pre_build.sh` otomatik çalışır
- ✅ Tüm bağımlılıklar kontrol edilir
- ✅ Eksik dosyalar otomatik oluşturulur

## 🔧 Nasıl Çalışıyor?

### Android Studio
1. **Gradle Pre-build Task:**
   - `android/app/build.gradle` içinde `generateDatabaseCode` task'ı tanımlı
   - Her build öncesi otomatik çalışır
   - Database code'u generate eder

2. **Icon Generation:**
   - `flutter_launcher_icons` paketi ile yapılandırılmış
   - İlk build'de otomatik oluşturulur

### Xcode
1. **Pre-build Scripts:**
   - `Runner.xcscheme` dosyasında pre-build action'lar tanımlı
   - Database code generation
   - Pod install kontrolü

2. **Build Phase:**
   - Xcode build öncesi otomatik script'ler çalışır

## 📝 Hala Manuel Olan

### iOS Signing
iOS için development team seçimi hala Xcode'da manuel yapılmalı:
1. Xcode'da Runner projesini aç
2. Signing & Capabilities sekmesine git
3. Team seç

**Not:** Bu güvenlik nedeniyle otomatikleştirilemez. Apple Developer hesabı gerektirir.

## 🚀 Kullanım

### İlk Kurulum
```bash
./setup.sh
```

Bu script:
- ✅ Flutter dependencies yükler
- ✅ Database code generate eder
- ✅ Android icons oluşturur
- ✅ iOS pods install eder
- ✅ Tüm pre-build hook'ları hazırlar

### Normal Build
Artık hiçbir şey yapmanıza gerek yok! Sadece:

**Android Studio:**
- Build → Make Project
- Her şey otomatik!

**Xcode:**
- Product → Build
- Her şey otomatik!

## 🔍 Kontrol Etme

### Database Code
```bash
# Kontrol et
ls -la lib/core/database/database.g.dart

# Manuel generate (gerekirse)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android Icons
```bash
# Kontrol et
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png

# Manuel generate (gerekirse)
flutter pub run flutter_launcher_icons:main
```

### iOS Pods
```bash
# Kontrol et
ls -la ios/Pods/

# Manuel install (gerekirse)
cd ios && pod install && cd ..
```

## 🐛 Sorun Giderme

### Database code generate edilmiyor
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android icons oluşmuyor
```bash
# flutter_launcher_icons paketini kontrol et
flutter pub get
flutter pub run flutter_launcher_icons:main

# Veya manuel script
bash scripts/generate_icons.sh
```

### iOS pods install edilmiyor
```bash
cd ios
pod deintegrate
pod install
cd ..
```

## 📚 İlgili Dosyalar

- `scripts/pre_build.sh` - Pre-build kontrol script'i
- `scripts/generate_icons.sh` - Icon generation script'i
- `android/app/build.gradle` - Gradle pre-build tasks
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` - Xcode pre-build scripts
