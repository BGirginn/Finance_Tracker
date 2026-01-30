# File Tree

```
finance/
├── .gitignore
├── README.md
├── PLAN.md
├── TREE.md
├── analysis_options.yaml
├── pubspec.yaml
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               └── kotlin/
│                   └── com/
│                       └── example/
│                           └── finance/
│                               └── MainActivity.kt
├── ios/
│   └── Runner/
│       └── Info.plist
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── database.dart
│   │   │   └── database.g.dart
│   │   ├── di/
│   │   │   └── providers.dart
│   │   ├── errors/
│   │   │   └── app_exception.dart
│   │   └── utils/
│   │       ├── category_keywords.dart
│   │       ├── date_utils.dart
│   │       └── money_utils.dart
│   ├── data/
│   │   └── repositories/
│   │       ├── investment_repository.dart
│   │       ├── ledger_repository.dart
│   │       ├── price_cache_repository.dart
│   │       └── scheduled_rule_repository.dart
│   ├── domain/
│   │   └── entities/
│   │       ├── investment_transaction.dart
│   │       ├── ledger_entry.dart
│   │       └── scheduled_rule.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── investment_provider.dart
│   │   │   ├── ledger_provider.dart
│   │   │   ├── report_provider.dart
│   │   │   └── scheduled_rule_provider.dart
│   │   ├── screens/
│   │   │   ├── dashboard/
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── investments/
│   │   │   │   ├── add_investment_screen.dart
│   │   │   │   └── investments_screen.dart
│   │   │   ├── scheduled_rules/
│   │   │   │   ├── add_scheduled_rule_screen.dart
│   │   │   │   └── scheduled_rules_screen.dart
│   │   │   ├── settings/
│   │   │   │   └── settings_screen.dart
│   │   │   └── transactions/
│   │   │       ├── add_transaction_screen.dart
│   │   │       └── transactions_screen.dart
│   │   └── widgets/
│   │       └── empty_state.dart
│   └── services/
│       ├── backup/
│       │   └── backup_service.dart
│       ├── background/
│       │   └── background_service.dart
│       ├── notification/
│       │   └── notification_service.dart
│       └── price/
│           ├── html_price_provider.dart
│           └── price_provider.dart
└── test/
    ├── export_import_roundtrip_test.dart
    ├── fifo_test.dart
    ├── price_provider_test.dart
    └── scheduled_rule_idempotency_test.dart
```

END_TREE
