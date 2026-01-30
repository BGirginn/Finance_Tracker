import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../data/repositories/scheduled_rule_repository.dart';
import '../../data/repositories/investment_repository.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/scheduled_rule.dart';
import '../../domain/entities/investment_transaction.dart';

class BackupService {
  final AppDatabase _database;
  final LedgerRepository _ledgerRepository;
  final ScheduledRuleRepository _ruleRepository;
  final InvestmentRepository _investmentRepository;

  BackupService({
    required AppDatabase database,
  })  : _database = database,
        _ledgerRepository = LedgerRepository(database),
        _ruleRepository = ScheduledRuleRepository(database),
        _investmentRepository = InvestmentRepository(database);

  Future<File> createBackup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final zipPath = p.join(tempDir.path, 'backup_$timestamp.zip');

      final archive = Archive();

      // Export ledger
      final ledgerEntries = await _ledgerRepository.getAllEntries();
      final ledgerCsv = _exportLedgerToCsv(ledgerEntries);
      archive.addFile(ArchiveFile('ledger.csv', ledgerCsv.length, ledgerCsv));

      // Export investments
      final investments = await _investmentRepository.getAllTransactions();
      final investmentsCsv = _exportInvestmentsToCsv(investments);
      archive.addFile(
        ArchiveFile('investments.csv', investmentsCsv.length, investmentsCsv),
      );

      // Export scheduled rules
      final rules = await _ruleRepository.getAllRules();
      final rulesCsv = _exportRulesToCsv(rules);
      archive.addFile(ArchiveFile('scheduled_rules.csv', rulesCsv.length, rulesCsv));

      // Export settings
      final settings = _exportSettings();
      archive.addFile(ArchiveFile('settings.json', settings.length, settings));

      // Create manifest
      final manifest = {
        'version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'recordCounts': {
          'ledger': ledgerEntries.length,
          'investments': investments.length,
          'scheduledRules': rules.length,
        },
      };
      final manifestJson = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json', manifestJson.length, manifestJson));

      // Create ZIP file
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        throw BackupException('Failed to create ZIP archive');
      }

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);

      return zipFile;
    } catch (e) {
      throw BackupException('Failed to create backup: $e');
    }
  }

  Future<void> restoreBackup(File backupFile, {bool replace = false}) async {
    try {
      final zipData = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipData);

      // Read manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) {
        throw BackupException('Manifest file not found in backup');
      }

      // Parse manifest for future use (version checking, etc.)
      final _ = jsonDecode(utf8.decode(manifestFile.content as List<int>));

      if (replace) {
        // Delete all existing data
        await _database.delete(_database.ledgerEntries).go();
        await _database.delete(_database.investmentTransactions).go();
        await _database.delete(_database.scheduledRules).go();
      }

      // Import ledger
      final ledgerFile = archive.findFile('ledger.csv');
      if (ledgerFile != null) {
        await _importLedgerFromCsv(ledgerFile.content as List<int>, replace);
      }

      // Import investments
      final investmentsFile = archive.findFile('investments.csv');
      if (investmentsFile != null) {
        await _importInvestmentsFromCsv(investmentsFile.content as List<int>, replace);
      }

      // Import scheduled rules
      final rulesFile = archive.findFile('scheduled_rules.csv');
      if (rulesFile != null) {
        await _importRulesFromCsv(rulesFile.content as List<int>, replace);
      }
    } catch (e) {
      throw BackupException('Failed to restore backup: $e');
    }
  }

  List<int> _exportLedgerToCsv(List<LedgerEntry> entries) {
    final rows = <List<dynamic>>[
      ['id', 'createdAt', 'date', 'type', 'amount', 'currency', 'category', 'note', 'source', 'raw'],
    ];

    for (final entry in entries) {
      rows.add([
        entry.id,
        entry.createdAt.toIso8601String(),
        entry.date.toIso8601String(),
        entry.type,
        entry.amount.toString(),
        entry.currency,
        entry.category ?? '',
        entry.note,
        entry.source,
        entry.raw ?? '',
      ]);
    }

    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  List<int> _exportInvestmentsToCsv(List<InvestmentTransaction> transactions) {
    final rows = <List<dynamic>>[
      [
        'id',
        'createdAt',
        'dateTime',
        'broker',
        'asset',
        'assetType',
        'action',
        'quantity',
        'unitPrice',
        'currency',
        'fees',
        'notes',
      ],
    ];

    for (final transaction in transactions) {
      rows.add([
        transaction.id,
        transaction.createdAt.toIso8601String(),
        transaction.dateTime.toIso8601String(),
        transaction.broker,
        transaction.asset,
        transaction.assetType.name,
        transaction.action.name,
        transaction.quantity.toString(),
        transaction.unitPrice.toString(),
        transaction.currency,
        transaction.fees.toString(),
        transaction.notes ?? '',
      ]);
    }

    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  List<int> _exportRulesToCsv(List<ScheduledRule> rules) {
    final rows = <List<dynamic>>[
      [
        'id',
        'enabled',
        'type',
        'amount',
        'currency',
        'category',
        'noteTemplate',
        'dayOfMonth',
        'time',
        'lastAppliedForDate',
        'createdAt',
      ],
    ];

    for (final rule in rules) {
      rows.add([
        rule.id,
        rule.enabled ? 1 : 0,
        rule.type,
        rule.amount.toString(),
        rule.currency,
        rule.category ?? '',
        rule.noteTemplate,
        rule.dayOfMonth,
        rule.time,
        rule.lastAppliedForDate?.toIso8601String() ?? '',
        rule.createdAt.toIso8601String(),
      ]);
    }

    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  List<int> _exportSettings() {
    final settings = {
      'defaultCurrency': 'TRY',
      'periodType': 'custom',
      'cutDay': 15,
    };
    return utf8.encode(jsonEncode(settings));
  }

  Future<void> _importLedgerFromCsv(List<int> csvData, bool replace) async {
    final csv = const CsvToListConverter().convert(utf8.decode(csvData));
    if (csv.isEmpty) return;

    final headers = csv[0];
    final entries = <LedgerEntry>[];

    for (int i = 1; i < csv.length; i++) {
      final row = csv[i];
      if (row.length < headers.length) continue;

      try {
        final entry = LedgerEntry(
          createdAt: DateTime.parse(row[1] as String),
          date: DateTime.parse(row[2] as String),
          type: row[3] as String,
          amount: Decimal.parse(row[4] as String),
          currency: row[5] as String,
          category: (row[6] as String).isEmpty ? null : row[6] as String,
          note: row[7] as String,
          source: row[8] as String,
          raw: (row[9] as String).isEmpty ? null : row[9] as String,
        );

        // Check for duplicates
        if (!replace) {
          final existing = await _ledgerRepository.getAllEntries();
          final isDuplicate = existing.any((e) =>
              e.date == entry.date &&
              e.amount == entry.amount &&
              e.note == entry.note);
          if (isDuplicate) continue;
        }

        entries.add(entry);
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    for (final entry in entries) {
      await _ledgerRepository.insertEntry(entry);
    }
  }

  Future<void> _importInvestmentsFromCsv(List<int> csvData, bool replace) async {
    final csv = const CsvToListConverter().convert(utf8.decode(csvData));
    if (csv.isEmpty) return;

    for (int i = 1; i < csv.length; i++) {
      final row = csv[i];
      if (row.length < 12) continue;

      try {
        final transaction = InvestmentTransaction(
          createdAt: DateTime.parse(row[1] as String),
          dateTime: DateTime.parse(row[2] as String),
          broker: row[3] as String,
          asset: row[4] as String,
          assetType: AssetType.values.firstWhere(
            (e) => e.name == row[5] as String,
            orElse: () => AssetType.other,
          ),
          action: InvestmentAction.values.firstWhere(
            (e) => e.name == row[6] as String,
          ),
          quantity: Decimal.parse(row[7] as String),
          unitPrice: Decimal.parse(row[8] as String),
          currency: row[9] as String,
          fees: Decimal.parse(row[10] as String),
          notes: (row[11] as String).isEmpty ? null : row[11] as String,
        );

        await _investmentRepository.insertTransaction(transaction);
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }
  }

  Future<void> _importRulesFromCsv(List<int> csvData, bool replace) async {
    final csv = const CsvToListConverter().convert(utf8.decode(csvData));
    if (csv.isEmpty) return;

    for (int i = 1; i < csv.length; i++) {
      final row = csv[i];
      if (row.length < 11) continue;

      try {
        final rule = ScheduledRule(
          enabled: (row[1] as int) == 1,
          type: row[2] as String,
          amount: Decimal.parse(row[3] as String),
          currency: row[4] as String,
          category: (row[5] as String).isEmpty ? null : row[5] as String,
          noteTemplate: row[6] as String,
          dayOfMonth: row[7] as int,
          time: row[8] as String,
          lastAppliedForDate: (row[9] as String).isEmpty
              ? null
              : DateTime.parse(row[9] as String),
          createdAt: DateTime.parse(row[10] as String),
        );

        await _ruleRepository.insertRule(rule);
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final database = ref.watch(databaseProvider);
  return BackupService(database: database);
});
