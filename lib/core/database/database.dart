import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/expense_category.dart';
import '../../domain/entities/investment_type.dart';

part 'database.g.dart';

// ExpenseCategory Table
@DataClassName('ExpenseCategoryData')
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// InvestmentType Table
@DataClassName('InvestmentTypeData')
class InvestmentTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// InvestmentCost Table
@DataClassName('InvestmentCostData')
class InvestmentCosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  TextColumn get costType => text()(); // 'commission', 'stamp_tax', 'bsmv', 'custody', 'transfer', 'other'
  TextColumn get amount => text()(); // Decimal as string
  TextColumn get currency => text().withDefault(const Constant('TRY'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// LedgerEntry Table
@DataClassName('LedgerEntryData')
class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get amount => text()(); // Decimal as string
  TextColumn get currency => text().withDefault(const Constant('TRY'))();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get category => text().nullable()(); // Legacy - will be migrated
  TextColumn get note => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual', 'scheduled', 'imported'
  TextColumn get raw => text().nullable()(); // JSON string
}

// ScheduledRule Table
@DataClassName('ScheduledRuleData')
class ScheduledRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get amount => text()(); // Decimal as string
  TextColumn get currency => text()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get category => text().nullable()(); // Legacy - will be migrated
  TextColumn get noteTemplate => text()();
  TextColumn get frequency => text().withDefault(const Constant('monthly'))(); // 'daily', 'weekly', 'monthly', 'yearly'
  IntColumn get dayOfMonth => integer().nullable()(); // 1-31
  IntColumn get dayOfWeek => integer().nullable()(); // 1-7 (Monday-Sunday)
  IntColumn get monthOfYear => integer().nullable()(); // 1-12
  TextColumn get time => text()(); // HH:mm format
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastAppliedForDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// InvestmentTransaction Table
@DataClassName('InvestmentTransactionData')
class InvestmentTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get transactionDate => dateTime().named('date_time')();
  TextColumn get broker => text()();
  TextColumn get asset => text()();
  IntColumn get assetTypeId => integer().nullable()();
  TextColumn get assetType => text()(); // Legacy - 'stock', 'crypto', 'forex', 'commodity', 'other'
  TextColumn get action => text()(); // 'buy' or 'sell'
  TextColumn get quantity => text()(); // Decimal as string
  TextColumn get unitPrice => text()(); // Decimal as string
  TextColumn get currency => text()();
  TextColumn get fees => text().withDefault(const Constant('0'))(); // Decimal as string - Legacy total fees
  TextColumn get notes => text().nullable()();
}

// PriceCache Table
class PriceCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get broker => text()();
  TextColumn get asset => text()();
  TextColumn get bid => text()(); // Decimal as string
  TextColumn get ask => text()(); // Decimal as string
  DateTimeColumn get timestamp => dateTime()();
}

@DriftDatabase(tables: [
  ExpenseCategories,
  InvestmentTypes,
  InvestmentCosts,
  LedgerEntries,
  ScheduledRules,
  InvestmentTransactions,
  PriceCaches,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories
        await _insertDefaultCategories();
        // Insert default investment types
        await _insertDefaultInvestmentTypes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Create new tables
          await m.createTable(expenseCategories);
          await m.createTable(investmentTypes);
          await m.createTable(investmentCosts);
          
          // Add new columns to existing tables
          await m.addColumn(ledgerEntries, ledgerEntries.categoryId);
          await m.addColumn(scheduledRules, scheduledRules.categoryId);
          await m.addColumn(scheduledRules, scheduledRules.frequency);
          await m.addColumn(scheduledRules, scheduledRules.dayOfWeek);
          await m.addColumn(scheduledRules, scheduledRules.monthOfYear);
          await m.addColumn(scheduledRules, scheduledRules.startDate);
          await m.addColumn(scheduledRules, scheduledRules.endDate);
          await m.addColumn(investmentTransactions, investmentTransactions.assetTypeId);
          
          // Insert default data
          await _insertDefaultCategories();
          await _insertDefaultInvestmentTypes();
        }
      },
    );
  }

  Future<void> _insertDefaultCategories() async {
    final defaults = getDefaultExpenseCategories();
    for (final category in defaults) {
      await into(expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(
          name: category.name,
          iconName: category.iconName,
          colorHex: category.colorHex,
          isDefault: Value(category.isDefault),
          sortOrder: Value(category.sortOrder),
        ),
      );
    }
  }

  Future<void> _insertDefaultInvestmentTypes() async {
    final defaults = getDefaultInvestmentTypes();
    for (final type in defaults) {
      await into(investmentTypes).insert(
        InvestmentTypesCompanion.insert(
          name: type.name,
          code: type.code,
          iconName: type.iconName,
          colorHex: type.colorHex,
          isDefault: Value(type.isDefault),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance.db'));
    return NativeDatabase.createInBackground(file);
  });
}
