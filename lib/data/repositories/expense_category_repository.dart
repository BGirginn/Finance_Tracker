import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/expense_category.dart';

class ExpenseCategoryRepository {
  final AppDatabase _database;

  ExpenseCategoryRepository(this._database);

  Future<List<ExpenseCategory>> getAllCategories() async {
    try {
      final categories = await (_database.select(_database.expenseCategories)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      return categories.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch expense categories: $e');
    }
  }

  Future<ExpenseCategory?> getCategoryById(int id) async {
    try {
      final category = await (_database.select(_database.expenseCategories)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return category != null ? _toEntity(category) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch expense category: $e');
    }
  }

  Future<ExpenseCategory?> getCategoryByName(String name) async {
    try {
      final category = await (_database.select(_database.expenseCategories)
            ..where((t) => t.name.equals(name)))
          .getSingleOrNull();
      return category != null ? _toEntity(category) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch expense category by name: $e');
    }
  }

  Future<ExpenseCategory> insertCategory(ExpenseCategory category) async {
    try {
      final companion = ExpenseCategoriesCompanion(
        name: Value(category.name),
        iconName: Value(category.iconName),
        colorHex: Value(category.colorHex),
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
      );

      final id = await _database.into(_database.expenseCategories).insert(companion);
      return category.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert expense category: $e');
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    try {
      if (category.id == null) {
        throw ValidationException('Category ID is required for update');
      }

      await (_database.update(_database.expenseCategories)
            ..where((t) => t.id.equals(category.id!)))
          .write(ExpenseCategoriesCompanion(
        name: Value(category.name),
        iconName: Value(category.iconName),
        colorHex: Value(category.colorHex),
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
      ));
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw DatabaseException('Failed to update expense category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await (_database.delete(_database.expenseCategories)
            ..where((t) => t.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete expense category: $e');
    }
  }

  Stream<List<ExpenseCategory>> watchAllCategories() {
    return (_database.select(_database.expenseCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  ExpenseCategory _toEntity(ExpenseCategoryData data) {
    return ExpenseCategory(
      id: data.id,
      name: data.name,
      iconName: data.iconName,
      colorHex: data.colorHex,
      isDefault: data.isDefault,
      sortOrder: data.sortOrder,
      createdAt: data.createdAt,
    );
  }
}
