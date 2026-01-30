import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/investment_cost.dart';

class InvestmentCostRepository {
  final AppDatabase _database;

  InvestmentCostRepository(this._database);

  Future<List<InvestmentCost>> getCostsByTransactionId(int transactionId) async {
    try {
      final costs = await (_database.select(_database.investmentCosts)
            ..where((t) => t.transactionId.equals(transactionId)))
          .get();
      return costs.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch investment costs: $e');
    }
  }

  Future<InvestmentCost> insertCost(InvestmentCost cost) async {
    try {
      final companion = InvestmentCostsCompanion(
        transactionId: Value(cost.transactionId),
        costType: Value(cost.costType.code),
        amount: Value(cost.amount.toString()),
        currency: Value(cost.currency),
        note: Value(cost.note),
      );

      final id = await _database.into(_database.investmentCosts).insert(companion);
      return cost.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert investment cost: $e');
    }
  }

  Future<void> insertCosts(List<InvestmentCost> costs) async {
    try {
      await _database.batch((batch) {
        for (final cost in costs) {
          batch.insert(
            _database.investmentCosts,
            InvestmentCostsCompanion(
              transactionId: Value(cost.transactionId),
              costType: Value(cost.costType.code),
              amount: Value(cost.amount.toString()),
              currency: Value(cost.currency),
              note: Value(cost.note),
            ),
          );
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to insert investment costs: $e');
    }
  }

  Future<void> updateCost(InvestmentCost cost) async {
    try {
      if (cost.id == null) {
        throw ValidationException('Cost ID is required for update');
      }

      await (_database.update(_database.investmentCosts)
            ..where((t) => t.id.equals(cost.id!)))
          .write(InvestmentCostsCompanion(
        costType: Value(cost.costType.code),
        amount: Value(cost.amount.toString()),
        currency: Value(cost.currency),
        note: Value(cost.note),
      ));
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw DatabaseException('Failed to update investment cost: $e');
    }
  }

  Future<void> deleteCost(int id) async {
    try {
      await (_database.delete(_database.investmentCosts)
            ..where((t) => t.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete investment cost: $e');
    }
  }

  Future<void> deleteCostsByTransactionId(int transactionId) async {
    try {
      await (_database.delete(_database.investmentCosts)
            ..where((t) => t.transactionId.equals(transactionId)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete investment costs: $e');
    }
  }

  Stream<List<InvestmentCost>> watchCostsByTransactionId(int transactionId) {
    return (_database.select(_database.investmentCosts)
          ..where((t) => t.transactionId.equals(transactionId)))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Future<Decimal> getTotalCostByTransactionId(int transactionId) async {
    final costs = await getCostsByTransactionId(transactionId);
    return costs.fold<Decimal>(Decimal.zero, (sum, cost) => sum + cost.amount);
  }

  InvestmentCost _toEntity(InvestmentCostData data) {
    return InvestmentCost(
      id: data.id,
      transactionId: data.transactionId,
      costType: InvestmentCostTypeExtension.fromCode(data.costType),
      amount: Decimal.parse(data.amount),
      currency: data.currency,
      note: data.note,
      createdAt: data.createdAt,
    );
  }
}
