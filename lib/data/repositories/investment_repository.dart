import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/investment_transaction.dart';

class InvestmentRepository {
  final AppDatabase _database;

  InvestmentRepository(this._database);

  Future<List<InvestmentTransaction>> getAllTransactions() async {
    try {
      final transactions = await _database.select(_database.investmentTransactions).get();
      return transactions.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch investment transactions: $e');
    }
  }

  Future<List<InvestmentTransaction>> getTransactionsByBrokerAndAsset(
    String broker,
    String asset,
  ) async {
    try {
      final transactions = await (_database.select(_database.investmentTransactions)
            ..where((tbl) =>
                tbl.broker.equals(broker) & tbl.asset.equals(asset))
            ..orderBy([(t) => OrderingTerm(expression: t.transactionDate)]))
          .get();
      return transactions.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch transactions by broker and asset: $e');
    }
  }

  Future<InvestmentTransaction> insertTransaction(InvestmentTransaction transaction) async {
    try {
      final companion = InvestmentTransactionsCompanion(
        transactionDate: Value(transaction.dateTime),
        broker: Value(transaction.broker),
        asset: Value(transaction.asset),
        assetTypeId: Value(transaction.assetTypeId),
        assetType: Value(transaction.assetType.name),
        action: Value(transaction.action.name),
        quantity: Value(transaction.quantity.toString()),
        unitPrice: Value(transaction.unitPrice.toString()),
        currency: Value(transaction.currency),
        fees: Value(transaction.fees.toString()),
        notes: Value(transaction.notes),
      );

      final id = await _database.into(_database.investmentTransactions).insert(companion);
      return transaction.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert investment transaction: $e');
    }
  }

  Future<void> updateTransaction(InvestmentTransaction transaction) async {
    try {
      if (transaction.id == null) {
        throw ValidationException('Transaction ID is required for update');
      }

      await (_database.update(_database.investmentTransactions)
            ..where((tbl) => tbl.id.equals(transaction.id!)))
          .write(InvestmentTransactionsCompanion(
        transactionDate: Value(transaction.dateTime),
        broker: Value(transaction.broker),
        asset: Value(transaction.asset),
        assetTypeId: Value(transaction.assetTypeId),
        assetType: Value(transaction.assetType.name),
        action: Value(transaction.action.name),
        quantity: Value(transaction.quantity.toString()),
        unitPrice: Value(transaction.unitPrice.toString()),
        currency: Value(transaction.currency),
        fees: Value(transaction.fees.toString()),
        notes: Value(transaction.notes),
      ));
    } catch (e) {
      throw DatabaseException('Failed to update investment transaction: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await (_database.delete(_database.investmentTransactions)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete investment transaction: $e');
    }
  }

  Future<List<InvestmentPosition>> calculatePositions() async {
    try {
      final transactions = await getAllTransactions();
      final positions = <String, InvestmentPosition>{};

      for (final transaction in transactions) {
        final key = '${transaction.broker}_${transaction.asset}';
        final position = positions[key];

        if (transaction.action == InvestmentAction.buy) {
          if (position == null) {
            positions[key] = InvestmentPosition(
              broker: transaction.broker,
              asset: transaction.asset,
              openQuantity: transaction.quantity,
              avgCost: (transaction.totalCost / transaction.quantity).toDecimal(scaleOnInfinitePrecision: 8),
              realizedPnL: Decimal.zero,
            );
          } else {
            final totalCost = (position.openQuantity * position.avgCost) + transaction.totalCost;
            final totalQuantity = position.openQuantity + transaction.quantity;
            positions[key] = InvestmentPosition(
              broker: transaction.broker,
              asset: transaction.asset,
              openQuantity: totalQuantity,
              avgCost: (totalCost / totalQuantity).toDecimal(scaleOnInfinitePrecision: 8),
              realizedPnL: position.realizedPnL,
            );
          }
        } else {
          // Sell
          if (position == null || position.openQuantity < transaction.quantity) {
            throw ValidationException('Insufficient quantity for sell transaction');
          }

          final costBasis = position.avgCost * transaction.quantity;
          final proceeds = transaction.quantity * transaction.unitPrice - transaction.fees;
          final realizedPnL = proceeds - costBasis;

          positions[key] = InvestmentPosition(
            broker: transaction.broker,
            asset: transaction.asset,
            openQuantity: position.openQuantity - transaction.quantity,
            avgCost: position.avgCost,
            realizedPnL: position.realizedPnL + realizedPnL,
          );
        }
      }

      return positions.values.where((p) => p.openQuantity > Decimal.zero).toList();
    } catch (e) {
      throw DatabaseException('Failed to calculate positions: $e');
    }
  }

  InvestmentTransaction _toEntity(InvestmentTransactionData data) {
    return InvestmentTransaction(
      id: data.id,
      createdAt: data.createdAt,
      dateTime: data.transactionDate,
      broker: data.broker,
      asset: data.asset,
      assetTypeId: data.assetTypeId,
      assetType: AssetType.values.firstWhere(
        (e) => e.name == data.assetType,
        orElse: () => AssetType.other,
      ),
      action: InvestmentAction.values.firstWhere(
        (e) => e.name == data.action,
      ),
      quantity: Decimal.parse(data.quantity),
      unitPrice: Decimal.parse(data.unitPrice),
      currency: data.currency,
      fees: Decimal.parse(data.fees),
      notes: data.notes,
    );
  }
}

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return InvestmentRepository(database);
});
