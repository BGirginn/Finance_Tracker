import 'package:flutter/material.dart';

class ExpenseCategory {
  final int? id;
  final String name;
  final String iconName;
  final String colorHex;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.isDefault = false,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get icon => iconDataFromName(iconName);
  Color get color => Color(0xFF000000 | int.parse(colorHex, radix: 16));

  static IconData iconDataFromName(String name) {
    return categoryIcons[name] ?? Icons.category;
  }

  static String iconNameFromData(IconData icon) {
    for (final entry in categoryIcons.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return 'category';
  }

  static const Map<String, IconData> categoryIcons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'receipt_long': Icons.receipt_long,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'shopping_bag': Icons.shopping_bag,
    'school': Icons.school,
    'home': Icons.home,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'fitness_center': Icons.fitness_center,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'travel_explore': Icons.travel_explore,
    'phone': Icons.phone,
    'wifi': Icons.wifi,
    'electric_bolt': Icons.electric_bolt,
    'water_drop': Icons.water_drop,
    'local_gas_station': Icons.local_gas_station,
    'checkroom': Icons.checkroom,
    'card_giftcard': Icons.card_giftcard,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'credit_card': Icons.credit_card,
    'account_balance': Icons.account_balance,
    'work': Icons.work,
    'payments': Icons.payments,
  };

  static const List<String> defaultColors = [
    'FF5722', // Deep Orange
    '2196F3', // Blue
    '4CAF50', // Green
    '9C27B0', // Purple
    'F44336', // Red
    '00BCD4', // Cyan
    'FF9800', // Orange
    '795548', // Brown
    '607D8B', // Blue Grey
    'E91E63', // Pink
    '3F51B5', // Indigo
    '009688', // Teal
  ];
}

/// Varsayılan harcama kategorileri
List<ExpenseCategory> getDefaultExpenseCategories() {
  return [
    ExpenseCategory(
      name: 'Gıda',
      iconName: 'restaurant',
      colorHex: 'FF5722',
      isDefault: true,
      sortOrder: 1,
    ),
    ExpenseCategory(
      name: 'Ulaşım',
      iconName: 'directions_car',
      colorHex: '2196F3',
      isDefault: true,
      sortOrder: 2,
    ),
    ExpenseCategory(
      name: 'Faturalar',
      iconName: 'receipt_long',
      colorHex: '4CAF50',
      isDefault: true,
      sortOrder: 3,
    ),
    ExpenseCategory(
      name: 'Eğlence',
      iconName: 'movie',
      colorHex: '9C27B0',
      isDefault: true,
      sortOrder: 4,
    ),
    ExpenseCategory(
      name: 'Sağlık',
      iconName: 'local_hospital',
      colorHex: 'F44336',
      isDefault: true,
      sortOrder: 5,
    ),
    ExpenseCategory(
      name: 'Alışveriş',
      iconName: 'shopping_bag',
      colorHex: '00BCD4',
      isDefault: true,
      sortOrder: 6,
    ),
    ExpenseCategory(
      name: 'Eğitim',
      iconName: 'school',
      colorHex: 'FF9800',
      isDefault: true,
      sortOrder: 7,
    ),
    ExpenseCategory(
      name: 'Kira',
      iconName: 'home',
      colorHex: '795548',
      isDefault: true,
      sortOrder: 8,
    ),
    ExpenseCategory(
      name: 'Diğer',
      iconName: 'more_horiz',
      colorHex: '607D8B',
      isDefault: true,
      sortOrder: 99,
    ),
  ];
}

/// Varsayılan gelir kategorileri
List<ExpenseCategory> getDefaultIncomeCategories() {
  return [
    ExpenseCategory(
      name: 'Maaş',
      iconName: 'attach_money',
      colorHex: '4CAF50', // Green
      isDefault: true,
      sortOrder: 1,
    ),
    ExpenseCategory(
      name: 'Yatırım',
      iconName: 'savings',
      colorHex: '3F51B5', // Indigo
      isDefault: true,
      sortOrder: 2,
    ),
    ExpenseCategory(
      name: 'Faiz',
      iconName: 'account_balance',
      colorHex: '009688', // Teal
      isDefault: true,
      sortOrder: 3,
    ),
  ];
}
