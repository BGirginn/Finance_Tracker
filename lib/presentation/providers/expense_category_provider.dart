import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/expense_category.dart';

/// Expense categories stream provider
final expenseCategoriesProvider = StreamProvider<List<ExpenseCategory>>((ref) {
  final repository = ref.watch(expenseCategoryRepositoryProvider);
  return repository.watchAllCategories();
});

/// Income categories provider (defaults)
final incomeCategoriesProvider = Provider<List<ExpenseCategory>>((ref) {
  return getDefaultIncomeCategories();
});

/// Expense categories list provider (non-streaming)
final expenseCategoriesListProvider = FutureProvider<List<ExpenseCategory>>((ref) {
  final repository = ref.watch(expenseCategoryRepositoryProvider);
  return repository.getAllCategories();
});

/// Single category by ID provider
final expenseCategoryByIdProvider = FutureProvider.family<ExpenseCategory?, int>((ref, id) {
  final repository = ref.watch(expenseCategoryRepositoryProvider);
  return repository.getCategoryById(id);
});

/// Expense category notifier for CRUD operations
class ExpenseCategoryNotifier extends StateNotifier<AsyncValue<List<ExpenseCategory>>> {
  final Ref _ref;

  ExpenseCategoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final repository = _ref.read(expenseCategoryRepositoryProvider);
      final categories = await repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadCategories();
  }

  Future<ExpenseCategory> addCategory(ExpenseCategory category) async {
    final repository = _ref.read(expenseCategoryRepositoryProvider);
    final newCategory = await repository.insertCategory(category);
    await _loadCategories();
    return newCategory;
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final repository = _ref.read(expenseCategoryRepositoryProvider);
    await repository.updateCategory(category);
    await _loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    final repository = _ref.read(expenseCategoryRepositoryProvider);
    await repository.deleteCategory(id);
    await _loadCategories();
  }
}

/// Expense category state notifier provider
final expenseCategoryNotifierProvider =
    StateNotifierProvider<ExpenseCategoryNotifier, AsyncValue<List<ExpenseCategory>>>((ref) {
  return ExpenseCategoryNotifier(ref);
});

/// In-memory income categories notifier (editable in settings)
class IncomeCategoryNotifier extends StateNotifier<List<ExpenseCategory>> {
  IncomeCategoryNotifier() : super(getDefaultIncomeCategories());

  Future<ExpenseCategory> addCategory(ExpenseCategory category) async {
    final newId = DateTime.now().millisecondsSinceEpoch;
    final newCat = category.copyWith(id: newId);
    state = [...state, newCat];
    return newCat;
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  Future<void> deleteCategory(int id) async {
    state = state.where((c) => c.id != id).toList();
  }
}

final incomeCategoryNotifierProvider = StateNotifierProvider<IncomeCategoryNotifier, List<ExpenseCategory>>((ref) {
  return IncomeCategoryNotifier();
});
