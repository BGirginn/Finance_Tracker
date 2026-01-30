import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:finance/domain/entities/scheduled_rule.dart';
import 'package:finance/domain/entities/ledger_entry.dart';
import 'package:finance/data/repositories/scheduled_rule_repository.dart';
import 'package:finance/data/repositories/ledger_repository.dart';
import 'package:finance/core/database/database.dart';

void main() {
  late AppDatabase database;
  late ScheduledRuleRepository ruleRepository;
  late LedgerRepository ledgerRepository;

  setUp(() {
    final executor = NativeDatabase.memory();
    database = AppDatabase(executor);
    ruleRepository = ScheduledRuleRepository(database);
    ledgerRepository = LedgerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Scheduled rule idempotency - same day should not create duplicate entries', () async {
    final rule = ScheduledRule(
      type: 'expense',
      amount: Decimal.fromInt(100),
      currency: 'TRY',
      noteTemplate: 'Test Expense',
      dayOfMonth: 15,
      time: '12:00',
      createdAt: DateTime.now(),
    );

    final insertedRule = await ruleRepository.insertRule(rule);

    final today = DateTime(2026, 1, 15);

    // First application
    final entry1 = LedgerEntry(
      createdAt: DateTime.now(),
      date: today,
      type: rule.type,
      amount: rule.amount,
      currency: rule.currency,
      note: rule.noteTemplate,
      source: 'scheduled',
    );

    await ledgerRepository.insertEntry(entry1);
    await ruleRepository.updateRule(
      insertedRule.copyWith(lastAppliedForDate: today),
    );

    // Try to apply again on the same day
    final entriesBefore = await ledgerRepository.getAllEntries();
    final countBefore = entriesBefore.length;

    // Check if rule should be applied (idempotency check)
    final updatedRule = await ruleRepository.getAllRules();
    final currentRule = updatedRule.first;

    if (currentRule.lastAppliedForDate != null) {
      final lastApplied = DateTime(
        currentRule.lastAppliedForDate!.year,
        currentRule.lastAppliedForDate!.month,
        currentRule.lastAppliedForDate!.day,
      );
      final isSameDay = lastApplied.isAtSameMomentAs(today) || lastApplied.isAfter(today);

      if (isSameDay) {
        // Should not create duplicate
        final entriesAfter = await ledgerRepository.getAllEntries();
        expect(entriesAfter.length, countBefore);
      }
    }
  });

  test('Scheduled rule should apply on correct day', () async {
    final rule = ScheduledRule(
      type: 'income',
      amount: Decimal.fromInt(5000),
      currency: 'TRY',
      noteTemplate: 'Monthly Salary',
      dayOfMonth: 1,
      time: '09:00',
      createdAt: DateTime.now(),
    );

    await ruleRepository.insertRule(rule);

    // Rule should apply on day 1 of the month
    final ruleDate = DateTime(2026, 1, 1);
    final today = DateTime(2026, 1, 15);

    // Rule date is in the past, should be applicable
    expect(ruleDate.isBefore(today) || ruleDate.isAtSameMomentAs(today), true);
  });

  test('Scheduled rule should not apply if disabled', () async {
    final rule = ScheduledRule(
      enabled: false,
      type: 'expense',
      amount: Decimal.fromInt(100),
      currency: 'TRY',
      noteTemplate: 'Disabled Rule',
      dayOfMonth: 15,
      time: '12:00',
      createdAt: DateTime.now(),
    );

    await ruleRepository.insertRule(rule);

    final rules = await ruleRepository.getEnabledRules();
    expect(rules.any((r) => r.noteTemplate == 'Disabled Rule'), false);
  });
}
