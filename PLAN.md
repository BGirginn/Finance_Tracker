# Flutter Kişisel Finans Uygulaması - Geliştirme Planı

## Proje Genel Bakış

Cross-platform (Android + iOS) offline-first kişisel finans uygulaması. SQLite (Drift) ile yerel veritabanı, Riverpod ile state yönetimi, planlı işlemler, yatırım takibi ve anlık fiyat entegrasyonu içerir.

## Milestones

### Milestone 1: Proje Kurulumu ve Temel Altyapı
- Flutter projesi oluşturma (null-safety)
- Bağımlılıkların eklenmesi (pubspec.yaml)
- Proje klasör yapısının oluşturulması
- Drift veritabanı şemasının tanımlanması
- Riverpod provider yapısının kurulması

### Milestone 2: Veri Modeli ve Veritabanı
- LedgerEntry, ScheduledRule, InvestmentTransaction modelleri
- Drift tablolarının implementasyonu
- Veritabanı migration stratejisi
- Repository pattern ile data access layer

### Milestone 3: Temel Özellikler - Ledger (Gelir/Gider)
- İşlem ekleme (income/expense)
- İşlem listesi, arama ve filtreleme
- İşlem düzenleme ve silme
- Boş durum ekranları
- Kategori yönetimi ve otomatik öneri sistemi

### Milestone 4: Raporlama Sistemi
- 15→15 periyot seçimi (takvim ayı veya özel kesim günü)
- Gelir/gider toplamları ve net hesaplama
- Kategori bazlı kırılım (liste + opsiyonel chart)
- Dashboard ekranı

### Milestone 5: Planlı İşlemler ve Bildirimler
- ScheduledRule CRUD işlemleri
- Aylık kural tanımlama (dayOfMonth + time)
- Idempotent otomatik kayıt ekleme
- iOS catch-up mekanizması (kaçan kayıtlar)
- Yerel bildirim entegrasyonu (flutter_local_notifications)
- Background task yapılandırması (workmanager + background_fetch)

### Milestone 6: Yatırım Takibi
- InvestmentTransaction CRUD
- FIFO cost hesaplama algoritması
- Realized P/L hesaplama
- Açık pozisyonlar listesi (openQuantity, avgCost, realizedPnL)
- Yatırım ekranları

### Milestone 7: Anlık Fiyat Entegrasyonu
- PriceProvider altyapısı (interface)
- HTML parser provider implementasyonu (örnek: XAU fiyatı)
- Bid/Ask fiyat çekme
- Unrealized P/L hesaplama
- Fiyat cache mekanizması (offline support)
- Dio ile network layer

### Milestone 8: Export/Backup/Restore
- CSV export (ledger, investments, scheduled_rules)
- Backup dosyası oluşturma (ZIP format)
- Restore mekanizması (merge/replace)
- Duplicate engelleme (date+amount+note veya UUID)
- Settings.json yönetimi

### Milestone 9: Testler
- FIFO realized P/L unit test
- PriceProvider parser test (fixture HTML, offline)
- Scheduled rule idempotency test
- Export/Import roundtrip test

### Milestone 10: UI/UX İyileştirmeleri
- Tüm ekranların tamamlanması
- Hata yönetimi ve user-friendly error states
- Loading states
- Responsive tasarım

## Riskler ve Çözümler

### Risk 1: iOS Background Execution Kısıtlamaları
**Risk:** iOS'ta background task'lar sınırlı çalışma süresine sahip. Planlı işlemler kaçabilir.
**Çözüm:** 
- Uygulama açılışında catch-up mekanizması (missed runs kontrolü)
- Background fetch ile periyodik kontrol
- LastAppliedForDate ile idempotency garantisi

### Risk 2: HTML Parser Kırılganlığı
**Risk:** Web sayfası yapısı değiştiğinde parser çalışmayabilir.
**Çözüm:**
- Provider interface ile kolay değiştirilebilir yapı
- Error handling ve fallback mekanizması
- Cache ile offline çalışma
- Test fixture'ları ile parser testleri

### Risk 3: FIFO Hesaplama Karmaşıklığı
**Risk:** Çoklu broker ve asset için FIFO doğru hesaplanmayabilir.
**Çözüm:**
- Broker+asset bazlı FIFO hesaplama
- Detaylı unit testler
- Transaction history ile doğrulama

### Risk 4: Veri Kaybı (Backup/Restore)
**Risk:** Restore sırasında veri kaybı veya duplicate kayıtlar.
**Çözüm:**
- UUID bazlı duplicate kontrolü
- Merge/Replace seçenekleri
- Backup versiyonlama
- Restore öncesi validation

## Veritabanı Şeması Özeti

### LedgerEntry Tablosu
- `id` (int, primary key, auto increment)
- `createdAt` (DateTime)
- `date` (DateTime, indexed)
- `type` (String: 'income' | 'expense')
- `amount` (Decimal)
- `currency` (String, default 'TRY')
- `category` (String, nullable)
- `note` (String, required)
- `source` (String: 'manual' | 'scheduled' | 'imported')
- `raw` (String, nullable, JSON)

### ScheduledRule Tablosu
- `id` (int, primary key, auto increment)
- `enabled` (bool, default true)
- `type` (String: 'income' | 'expense')
- `amount` (Decimal)
- `currency` (String)
- `category` (String, nullable)
- `noteTemplate` (String)
- `dayOfMonth` (int, 1-31)
- `time` (String, HH:mm format)
- `lastAppliedForDate` (DateTime, nullable)
- `createdAt` (DateTime)

### InvestmentTransaction Tablosu
- `id` (int, primary key, auto increment)
- `createdAt` (DateTime)
- `dateTime` (DateTime, indexed)
- `broker` (String)
- `asset` (String)
- `assetType` (String: 'stock' | 'crypto' | 'forex' | 'commodity' | 'other')
- `action` (String: 'buy' | 'sell')
- `quantity` (Decimal)
- `unitPrice` (Decimal)
- `currency` (String)
- `fees` (Decimal, default 0)
- `notes` (String, nullable)

### PriceCache Tablosu (opsiyonel, performans için)
- `id` (int, primary key)
- `broker` (String)
- `asset` (String)
- `bid` (Decimal)
- `ask` (Decimal)
- `timestamp` (DateTime)
- Unique constraint: (broker, asset)

## Backup Format ve Versiyonlama

### Backup Dosya Yapısı (ZIP)
```
backup_YYYYMMDD_HHMMSS.zip
├── manifest.json          # Versiyon, tarih, cihaz bilgisi
├── ledger.csv
├── investments.csv
├── scheduled_rules.csv
└── settings.json
```

### manifest.json Formatı
```json
{
  "version": "1.0.0",
  "createdAt": "2026-01-26T10:30:00Z",
  "deviceInfo": "...",
  "recordCounts": {
    "ledger": 150,
    "investments": 25,
    "scheduledRules": 5
  }
}
```

### CSV Formatları

**ledger.csv:**
- Header: id,createdAt,date,type,amount,currency,category,note,source,raw
- Encoding: UTF-8 with BOM

**investments.csv:**
- Header: id,createdAt,dateTime,broker,asset,assetType,action,quantity,unitPrice,currency,fees,notes

**scheduled_rules.csv:**
- Header: id,enabled,type,amount,currency,category,noteTemplate,dayOfMonth,time,lastAppliedForDate,createdAt

### Versiyonlama Stratejisi
- Major.Minor.Patch formatı
- Breaking changes için major version artışı
- Yeni alanlar için minor version artışı
- Restore sırasında version kontrolü ve uyumluluk kontrolü

## Teknik Mimari

### Klasör Yapısı
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   ├── di/
│   ├── errors/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── providers/
├── domain/
│   ├── entities/
│   └── usecases/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── services/
    ├── notification/
    ├── background/
    └── price/
```

### State Management (Riverpod)
- Provider'lar feature bazlı organize edilecek
- AsyncNotifier pattern kullanılacak
- Error ve loading state'leri merkezi yönetilecek

### Dependency Injection
- Riverpod ile DI
- Repository'ler provider olarak expose edilecek
- Service'ler singleton provider olarak tanımlanacak

## Test Stratejisi

### Unit Testler
- FIFO hesaplama algoritması
- PriceProvider HTML parser
- Scheduled rule idempotency logic
- Export/Import utilities

### Widget Testler
- Kritik form ekranları
- List widget'ları

### Integration Testler
- Export/Import roundtrip
- Scheduled transaction flow

## Bağımlılıklar (pubspec.yaml)

**Core:**
- flutter_riverpod: ^2.x
- drift: ^2.x
- sqlite3_flutter_libs: ^0.5.x
- path_provider: ^2.x

**Networking:**
- dio: ^5.x
- html: ^0.15.x (parser için)

**Background & Notifications:**
- workmanager: ^0.5.x
- flutter_background_service: ^5.x (iOS için alternatif)
- flutter_local_notifications: ^16.x

**UI:**
- fl_chart: ^0.66.x (opsiyonel)
- intl: ^0.19.x (tarih/para formatı)

**File Operations:**
- file_picker: ^6.x
- share_plus: ^7.x
- archive: ^3.x (ZIP için)
- path: ^1.x

**Utilities:**
- uuid: ^4.x
- decimal: ^2.x (para hesaplamaları için)

## Geliştirme Sırası

1. **Hafta 1:** Milestone 1-2 (Kurulum + DB)
2. **Hafta 2:** Milestone 3-4 (Ledger + Raporlama)
3. **Hafta 3:** Milestone 5 (Planlı İşlemler)
4. **Hafta 4:** Milestone 6-7 (Yatırım + Fiyat)
5. **Hafta 5:** Milestone 8-9 (Backup + Testler)
6. **Hafta 6:** Milestone 10 (UI/UX polish)

## Notlar

- Tüm para hesaplamaları Decimal tipi ile yapılacak (floating point hatalarından kaçınmak için)
- Offline-first yaklaşım: network hataları graceful handle edilecek
- Kullanıcı dostu hata mesajları ve retry mekanizmaları
- Accessibility desteği (opsiyonel ama önerilir)
- Dark mode desteği (opsiyonel ama önerilir)
