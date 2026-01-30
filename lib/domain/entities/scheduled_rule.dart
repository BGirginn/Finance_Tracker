import 'package:decimal/decimal.dart';

enum RuleFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

extension RuleFrequencyExtension on RuleFrequency {
  String get displayName {
    switch (this) {
      case RuleFrequency.daily:
        return 'Günlük';
      case RuleFrequency.weekly:
        return 'Haftalık';
      case RuleFrequency.monthly:
        return 'Aylık';
      case RuleFrequency.yearly:
        return 'Yıllık';
    }
  }

  String get code {
    switch (this) {
      case RuleFrequency.daily:
        return 'daily';
      case RuleFrequency.weekly:
        return 'weekly';
      case RuleFrequency.monthly:
        return 'monthly';
      case RuleFrequency.yearly:
        return 'yearly';
    }
  }

  static RuleFrequency fromCode(String code) {
    switch (code) {
      case 'daily':
        return RuleFrequency.daily;
      case 'weekly':
        return RuleFrequency.weekly;
      case 'monthly':
        return RuleFrequency.monthly;
      case 'yearly':
        return RuleFrequency.yearly;
      default:
        return RuleFrequency.monthly;
    }
  }
}

class ScheduledRule {
  final int? id;
  final bool enabled;
  final String type; // 'income' or 'expense'
  final Decimal amount;
  final String currency;
  final int? categoryId;
  final String? category; // Legacy - for backward compatibility
  final String noteTemplate;
  final RuleFrequency frequency;
  final int? dayOfMonth; // 1-31 (for monthly/yearly)
  final int? dayOfWeek; // 1-7 Monday-Sunday (for weekly)
  final int? monthOfYear; // 1-12 (for yearly)
  final String time; // HH:mm format
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? lastAppliedForDate;
  final DateTime createdAt;

  ScheduledRule({
    this.id,
    this.enabled = true,
    required this.type,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.category,
    required this.noteTemplate,
    this.frequency = RuleFrequency.monthly,
    this.dayOfMonth,
    this.dayOfWeek,
    this.monthOfYear,
    required this.time,
    this.startDate,
    this.endDate,
    this.lastAppliedForDate,
    required this.createdAt,
  });

  ScheduledRule copyWith({
    int? id,
    bool? enabled,
    String? type,
    Decimal? amount,
    String? currency,
    int? categoryId,
    String? category,
    String? noteTemplate,
    RuleFrequency? frequency,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
    String? time,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastAppliedForDate,
    DateTime? createdAt,
  }) {
    return ScheduledRule(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      noteTemplate: noteTemplate ?? this.noteTemplate,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastAppliedForDate: lastAppliedForDate ?? this.lastAppliedForDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
