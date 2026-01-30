import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/investment_type.dart';

class InvestmentTypeRepository {
  final AppDatabase _database;

  InvestmentTypeRepository(this._database);

  Future<List<InvestmentType>> getAllTypes() async {
    try {
      final types = await _database.select(_database.investmentTypes).get();
      return types.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch investment types: $e');
    }
  }

  Future<InvestmentType?> getTypeById(int id) async {
    try {
      final type = await (_database.select(_database.investmentTypes)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return type != null ? _toEntity(type) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch investment type: $e');
    }
  }

  Future<InvestmentType?> getTypeByCode(String code) async {
    try {
      final type = await (_database.select(_database.investmentTypes)
            ..where((t) => t.code.equals(code)))
          .getSingleOrNull();
      return type != null ? _toEntity(type) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch investment type by code: $e');
    }
  }

  Future<InvestmentType> insertType(InvestmentType type) async {
    try {
      final companion = InvestmentTypesCompanion(
        name: Value(type.name),
        code: Value(type.code),
        iconName: Value(type.iconName),
        colorHex: Value(type.colorHex),
        isDefault: Value(type.isDefault),
      );

      final id = await _database.into(_database.investmentTypes).insert(companion);
      return type.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to insert investment type: $e');
    }
  }

  Future<void> updateType(InvestmentType type) async {
    try {
      if (type.id == null) {
        throw ValidationException('Type ID is required for update');
      }

      await (_database.update(_database.investmentTypes)
            ..where((t) => t.id.equals(type.id!)))
          .write(InvestmentTypesCompanion(
        name: Value(type.name),
        code: Value(type.code),
        iconName: Value(type.iconName),
        colorHex: Value(type.colorHex),
        isDefault: Value(type.isDefault),
      ));
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw DatabaseException('Failed to update investment type: $e');
    }
  }

  Future<void> deleteType(int id) async {
    try {
      await (_database.delete(_database.investmentTypes)
            ..where((t) => t.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete investment type: $e');
    }
  }

  Stream<List<InvestmentType>> watchAllTypes() {
    return _database
        .select(_database.investmentTypes)
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  InvestmentType _toEntity(InvestmentTypeData data) {
    return InvestmentType(
      id: data.id,
      name: data.name,
      code: data.code,
      iconName: data.iconName,
      colorHex: data.colorHex,
      isDefault: data.isDefault,
      createdAt: data.createdAt,
    );
  }
}
