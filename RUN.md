# Run Instructions

## Initial Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Generate database code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Development

### Analyze code:
```bash
flutter analyze
```

### Run tests:
```bash
flutter test
```

### Run the app:
```bash
flutter run
```

## Build

### Android:
```bash
flutter build apk
```

### iOS:
```bash
flutter build ios
```

END_RUN
