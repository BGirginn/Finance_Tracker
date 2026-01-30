import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/scheduled_rule.dart';

class ScheduledRuleRepository {
  final AppDatabase _database;

  ScheduledRuleRepository(this._database);

  Future<List<ScheduledRule>> getAllRules() async {
    try {
      final rules = await _database.select(_database.scheduledRules).get();
      return rules.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch scheduled rules: $e');
    }
  }

  Future<List<ScheduledRule>> getEnabledRules() async {
    try {
      final rules = await (_database.select(_database.scheduledRules)
            ..where((tbl) => tbl.enabled.equals(true)))
          .get();
      return rules.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch enabled scheduled rules: $e');
    }
  }

  Future<ScheduledRule> insertRule(ScheduledRule rule) async {
    try {
      final companion = ScheduledRulesCompanion(
        enabled: Value(rule.enabled),
        type: Value(rule.type),
        amount: Value(rule.amount.toString()),
        currency: Value(rule.currency),
        categoryId: Value(rule.categoryId),
        category: Value(rule.category),
        noteTemplate: Value(rule.noteTemplate),
        frequency: Value(rule.frequency.code),
        dayOfMonth: Value(rule.dayOfMonth),
        dayOfWeek: Value(rule.dayOfWeek),
        monthOfYear: Value(rule.monthOfYear),
        time: Value(rule.time),
        startDate: Value(rule.startDate),
        endDate: Value(rule.endDate),
        lastAppliedForDate: Value(rule.lastAppliedForDate),
      );

      final id = await _database.into(_database.scheduledRules).insert(companion);
      return rule.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert scheduled rule: $e');
    }
  }

  Future<void> updateRule(ScheduledRule rule) async {
    try {
      if (rule.id == null) {
        throw ValidationException('Rule ID is required for update');
      }

      await (_database.update(_database.scheduledRules)
            ..where((tbl) => tbl.id.equals(rule.id!)))
          .write(ScheduledRulesCompanion(
        enabled: Value(rule.enabled),
        type: Value(rule.type),
        amount: Value(rule.amount.toString()),
        currency: Value(rule.currency),
        categoryId: Value(rule.categoryId),
        category: Value(rule.category),
        noteTemplate: Value(rule.noteTemplate),
        frequency: Value(rule.frequency.code),
        dayOfMonth: Value(rule.dayOfMonth),
        dayOfWeek: Value(rule.dayOfWeek),
        monthOfYear: Value(rule.monthOfYear),
        time: Value(rule.time),
        startDate: Value(rule.startDate),
        endDate: Value(rule.endDate),
        lastAppliedForDate: Value(rule.lastAppliedForDate),
      ));
    } catch (e) {
      throw DatabaseException('Failed to update scheduled rule: $e');
    }
  }

  Future<void> deleteRule(int id) async {
    try {
      await (_database.delete(_database.scheduledRules)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete scheduled rule: $e');
    }
  }

  ScheduledRule _toEntity(ScheduledRuleData data) {
    return ScheduledRule(
      id: data.id,
      enabled: data.enabled,
      type: data.type,
      amount: Decimal.parse(data.amount),
      currency: data.currency,
      categoryId: data.categoryId,
      category: data.category,
      noteTemplate: data.noteTemplate,
      frequency: RuleFrequencyExtension.fromCode(data.frequency),
      dayOfMonth: data.dayOfMonth,
      dayOfWeek: data.dayOfWeek,
      monthOfYear: data.monthOfYear,
      time: data.time,
      startDate: data.startDate,
      endDate: data.endDate,
      lastAppliedForDate: data.lastAppliedForDate,
      createdAt: data.createdAt,
    );
  }
}

final scheduledRuleRepositoryProvider = Provider<ScheduledRuleRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ScheduledRuleRepository(database);
});
