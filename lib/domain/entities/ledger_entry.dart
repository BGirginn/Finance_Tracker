import 'package:decimal/decimal.dart';

class LedgerEntry {
  final int? id;
  final DateTime createdAt;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final Decimal amount;
  final String currency;
  final int? categoryId;
  final String? category; // Legacy - for backward compatibility
  final String note;
  final String source; // 'manual', 'scheduled', 'imported'
  final String? raw; // JSON string

  LedgerEntry({
    this.id,
    required this.createdAt,
    required this.date,
    required this.type,
    required this.amount,
    this.currency = 'TRY',
    this.categoryId,
    this.category,
    required this.note,
    this.source = 'manual',
    this.raw,
  });

  LedgerEntry copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? date,
    String? type,
    Decimal? amount,
    String? currency,
    int? categoryId,
    String? category,
    String? note,
    String? source,
    String? raw,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      note: note ?? this.note,
      source: source ?? this.source,
      raw: raw ?? this.raw,
    );
  }
}
