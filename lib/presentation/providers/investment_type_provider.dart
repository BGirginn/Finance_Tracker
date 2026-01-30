import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/investment_type.dart';

/// Investment types stream provider
final investmentTypesProvider = StreamProvider<List<InvestmentType>>((ref) {
  final repository = ref.watch(investmentTypeRepositoryProvider);
  return repository.watchAllTypes();
});

/// Investment types list provider (non-streaming)
final investmentTypesListProvider = FutureProvider<List<InvestmentType>>((ref) {
  final repository = ref.watch(investmentTypeRepositoryProvider);
  return repository.getAllTypes();
});

/// Single type by ID provider
final investmentTypeByIdProvider = FutureProvider.family<InvestmentType?, int>((ref, id) {
  final repository = ref.watch(investmentTypeRepositoryProvider);
  return repository.getTypeById(id);
});

/// Single type by code provider
final investmentTypeByCodeProvider = FutureProvider.family<InvestmentType?, String>((ref, code) {
  final repository = ref.watch(investmentTypeRepositoryProvider);
  return repository.getTypeByCode(code);
});

/// Investment type notifier for CRUD operations
class InvestmentTypeNotifier extends StateNotifier<AsyncValue<List<InvestmentType>>> {
  final Ref _ref;

  InvestmentTypeNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final repository = _ref.read(investmentTypeRepositoryProvider);
      final types = await repository.getAllTypes();
      state = AsyncValue.data(types);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadTypes();
  }

  Future<InvestmentType> addType(InvestmentType type) async {
    final repository = _ref.read(investmentTypeRepositoryProvider);
    final newType = await repository.insertType(type);
    await _loadTypes();
    return newType;
  }

  Future<void> updateType(InvestmentType type) async {
    final repository = _ref.read(investmentTypeRepositoryProvider);
    await repository.updateType(type);
    await _loadTypes();
  }

  Future<void> deleteType(int id) async {
    final repository = _ref.read(investmentTypeRepositoryProvider);
    await repository.deleteType(id);
    await _loadTypes();
  }
}

/// Investment type state notifier provider
final investmentTypeNotifierProvider =
    StateNotifierProvider<InvestmentTypeNotifier, AsyncValue<List<InvestmentType>>>((ref) {
  return InvestmentTypeNotifier(ref);
});
