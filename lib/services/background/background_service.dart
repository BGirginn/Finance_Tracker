import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../data/repositories/scheduled_rule_repository.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/scheduled_rule.dart';
import '../notification/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize database
      final database = AppDatabase();
      final ruleRepository = ScheduledRuleRepository(database);
      final ledgerRepository = LedgerRepository(database);

      // Get enabled rules
      final rules = await ruleRepository.getEnabledRules();
      final now = DateTime.now();

      for (final rule in rules) {
        await _processScheduledRule(rule, now, ruleRepository, ledgerRepository);
      }

      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> _processScheduledRule(
  ScheduledRule rule,
  DateTime now,
  ScheduledRuleRepository ruleRepository,
  LedgerRepository ledgerRepository,
) async {
  if (!rule.enabled) return;

  final today = DateTime(now.year, now.month, now.day);
  final dayOfMonth = rule.dayOfMonth ?? 1;
  final ruleDate = DateTime(now.year, now.month, dayOfMonth);

  // Check if rule should be applied today
  if (ruleDate.isAfter(today)) return;

  // Check idempotency: if already applied for this period
  if (rule.lastAppliedForDate != null) {
    final lastApplied = DateTime(
      rule.lastAppliedForDate!.year,
      rule.lastAppliedForDate!.month,
      rule.lastAppliedForDate!.day,
    );
    if (lastApplied.isAtSameMomentAs(today) || lastApplied.isAfter(today)) {
      return; // Already applied
    }
  }

  // Create ledger entry
  final entry = LedgerEntry(
    createdAt: DateTime.now(),
    date: ruleDate,
    type: rule.type,
    amount: rule.amount,
    currency: rule.currency,
    categoryId: rule.categoryId,
    category: rule.category,
    note: rule.noteTemplate,
    source: 'scheduled',
  );

  await ledgerRepository.insertEntry(entry);

  // Update lastAppliedForDate
  await ruleRepository.updateRule(rule.copyWith(lastAppliedForDate: today));
}

class BackgroundService {
  static const String taskName = 'processScheduledTransactions';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  // For use from main.dart with direct instances
  static Future<void> processScheduledRulesFromContainer(
    AppDatabase database,
    NotificationService notificationService,
  ) async {
    final ruleRepository = ScheduledRuleRepository(database);
    final ledgerRepository = LedgerRepository(database);

    final rules = await ruleRepository.getEnabledRules();
    final now = DateTime.now();

    for (final rule in rules) {
      await _processScheduledRuleWithNotification(
        rule,
        now,
        ruleRepository,
        ledgerRepository,
        notificationService,
      );
    }
  }

  static Future<void> processScheduledRules(Ref ref) async {
    final database = ref.read(databaseProvider);
    final ruleRepository = ScheduledRuleRepository(database);
    final ledgerRepository = LedgerRepository(database);
    final notificationService = ref.read(notificationServiceProvider);

    final rules = await ruleRepository.getEnabledRules();
    final now = DateTime.now();

    for (final rule in rules) {
      await _processScheduledRuleWithNotification(
        rule,
        now,
        ruleRepository,
        ledgerRepository,
        notificationService,
      );
    }
  }

  static Future<void> _processScheduledRuleWithNotification(
    ScheduledRule rule,
    DateTime now,
    ScheduledRuleRepository ruleRepository,
    LedgerRepository ledgerRepository,
    NotificationService notificationService,
  ) async {
    if (!rule.enabled) return;

    final today = DateTime(now.year, now.month, now.day);
    final dayOfMonth = rule.dayOfMonth ?? 1;
    final ruleDate = DateTime(now.year, now.month, dayOfMonth);

    // Check if rule should be applied today
    if (ruleDate.isAfter(today)) return;

    // Check idempotency
    if (rule.lastAppliedForDate != null) {
      final lastApplied = DateTime(
        rule.lastAppliedForDate!.year,
        rule.lastAppliedForDate!.month,
        rule.lastAppliedForDate!.day,
      );
      if (lastApplied.isAtSameMomentAs(today) || lastApplied.isAfter(today)) {
        return;
      }
    }

    // Create ledger entry
    final entry = LedgerEntry(
      createdAt: DateTime.now(),
      date: ruleDate,
      type: rule.type,
      amount: rule.amount,
      currency: rule.currency,
      categoryId: rule.categoryId,
      category: rule.category,
      note: rule.noteTemplate,
      source: 'scheduled',
    );

    await ledgerRepository.insertEntry(entry);

    // Send notification
    await notificationService.showScheduledTransactionNotification(
      type: rule.type,
      amount: rule.amount.toString(),
      currency: rule.currency,
      date: ruleDate,
    );

    // Update lastAppliedForDate
    await ruleRepository.updateRule(rule.copyWith(lastAppliedForDate: today));
  }
}
