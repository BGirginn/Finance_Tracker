import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/investment_repository.dart';
import '../../domain/entities/investment_transaction.dart';

final investmentTransactionsProvider =
    FutureProvider<List<InvestmentTransaction>>((ref) async {
  final repository = ref.watch(investmentRepositoryProvider);
  return repository.getAllTransactions();
});

final investmentPositionsProvider =
    FutureProvider<List<InvestmentPosition>>((ref) async {
  final repository = ref.watch(investmentRepositoryProvider);
  return repository.calculatePositions();
});
