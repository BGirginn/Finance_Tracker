import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:finance/domain/entities/ledger_entry.dart';
import 'package:finance/data/repositories/ledger_repository.dart';
import 'package:finance/core/database/database.dart';
import 'package:finance/services/backup/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late AppDatabase database;
  late LedgerRepository repository;
  late BackupService backupService;

  setUp(() {
    final executor = NativeDatabase.memory();
    database = AppDatabase(executor);
    repository = LedgerRepository(database);
    backupService = BackupService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Export/Import roundtrip test for ledger entries', skip: 'Requires path_provider plugin mock', () async {
    // Create test entries
    final entry1 = LedgerEntry(
      createdAt: DateTime(2026, 1, 1),
      date: DateTime(2026, 1, 1),
      type: 'income',
      amount: Decimal.fromInt(5000),
      currency: 'TRY',
      category: 'Maaş',
      note: 'Monthly Salary',
      source: 'manual',
    );

    final entry2 = LedgerEntry(
      createdAt: DateTime(2026, 1, 2),
      date: DateTime(2026, 1, 2),
      type: 'expense',
      amount: Decimal.fromInt(100),
      currency: 'TRY',
      category: 'Yemek',
      note: 'Lunch',
      source: 'manual',
    );

    await repository.insertEntry(entry1);
    await repository.insertEntry(entry2);

    // Export backup
    final backupFile = await backupService.createBackup();
    expect(backupFile.existsSync(), true);

    // Clear database
    final allEntries = await repository.getAllEntries();
    for (final entry in allEntries) {
      if (entry.id != null) {
        await repository.deleteEntry(entry.id!);
      }
    }

    // Verify database is empty
    final entriesAfterDelete = await repository.getAllEntries();
    expect(entriesAfterDelete.length, 0);

    // Restore backup
    await backupService.restoreBackup(backupFile, replace: true);

    // Verify entries are restored
    final restoredEntries = await repository.getAllEntries();
    expect(restoredEntries.length, 2);

    // Verify entry details
    final restoredEntry1 = restoredEntries.firstWhere(
      (e) => e.note == 'Monthly Salary',
    );
    expect(restoredEntry1.type, 'income');
    expect(restoredEntry1.amount, Decimal.fromInt(5000));
    expect(restoredEntry1.category, 'Maaş');

    final restoredEntry2 = restoredEntries.firstWhere(
      (e) => e.note == 'Lunch',
    );
    expect(restoredEntry2.type, 'expense');
    expect(restoredEntry2.amount, Decimal.fromInt(100));
    expect(restoredEntry2.category, 'Yemek');

    // Cleanup
    await backupFile.delete();
  });

  test('Export/Import with duplicate prevention', skip: 'Requires path_provider plugin mock', () async {
    final entry = LedgerEntry(
      createdAt: DateTime(2026, 1, 1),
      date: DateTime(2026, 1, 1),
      type: 'income',
      amount: Decimal.fromInt(1000),
      currency: 'TRY',
      note: 'Test Entry',
      source: 'manual',
    );

    await repository.insertEntry(entry);

    // Export
    final backupFile = await backupService.createBackup();

    // Restore with merge (should not create duplicate)
    final entriesBefore = await repository.getAllEntries();
    final countBefore = entriesBefore.length;

    await backupService.restoreBackup(backupFile, replace: false);

    final entriesAfter = await repository.getAllEntries();
    // Should have same count (duplicate prevented)
    expect(entriesAfter.length, countBefore);

    // Cleanup
    await backupFile.delete();
  });
}
