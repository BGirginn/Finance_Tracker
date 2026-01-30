import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/ledger_entry.dart';

class LedgerRepository {
  final AppDatabase _database;

  LedgerRepository(this._database);

  Future<List<LedgerEntry>> getAllEntries() async {
    try {
      final entries = await _database.select(_database.ledgerEntries).get();
      return entries.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch ledger entries: $e');
    }
  }

  Future<List<LedgerEntry>> searchEntries(String query) async {
    try {
      final entries = await (_database.select(_database.ledgerEntries)
            ..where((tbl) => tbl.note.like('%$query%')))
          .get();
      return entries.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to search ledger entries: $e');
    }
  }

  Future<List<LedgerEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final entries = await (_database.select(_database.ledgerEntries)
            ..where((tbl) =>
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerOrEqualValue(end)))
          .get();
      return entries.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries by date range: $e');
    }
  }

  Future<LedgerEntry> insertEntry(LedgerEntry entry) async {
    try {
      final companion = LedgerEntriesCompanion(
        date: Value(entry.date),
        type: Value(entry.type),
        amount: Value(entry.amount.toString()),
        currency: Value(entry.currency),
        categoryId: Value(entry.categoryId),
        category: Value(entry.category),
        note: Value(entry.note),
        source: Value(entry.source),
        raw: Value(entry.raw),
      );

      final id = await _database.into(_database.ledgerEntries).insert(companion);
      return entry.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert ledger entry: $e');
    }
  }

  Future<void> updateEntry(LedgerEntry entry) async {
    try {
      if (entry.id == null) {
        throw ValidationException('Entry ID is required for update');
      }

      await (_database.update(_database.ledgerEntries)
            ..where((tbl) => tbl.id.equals(entry.id!)))
          .write(LedgerEntriesCompanion(
        date: Value(entry.date),
        type: Value(entry.type),
        amount: Value(entry.amount.toString()),
        currency: Value(entry.currency),
        categoryId: Value(entry.categoryId),
        category: Value(entry.category),
        note: Value(entry.note),
        source: Value(entry.source),
        raw: Value(entry.raw),
      ));
    } catch (e) {
      throw DatabaseException('Failed to update ledger entry: $e');
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await (_database.delete(_database.ledgerEntries)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete ledger entry: $e');
    }
  }

  LedgerEntry _toEntity(LedgerEntryData data) {
    return LedgerEntry(
      id: data.id,
      createdAt: data.createdAt,
      date: data.date,
      type: data.type,
      amount: Decimal.parse(data.amount),
      currency: data.currency,
      categoryId: data.categoryId,
      category: data.category,
      note: data.note,
      source: data.source,
      raw: data.raw,
    );
  }
}

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return LedgerRepository(database);
});
