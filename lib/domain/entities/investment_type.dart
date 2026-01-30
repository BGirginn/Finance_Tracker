import 'package:flutter/material.dart';

class InvestmentType {
  final int? id;
  final String name;
  final String code;
  final String iconName;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  InvestmentType({
    this.id,
    required this.name,
    required this.code,
    required this.iconName,
    required this.colorHex,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  InvestmentType copyWith({
    int? id,
    String? name,
    String? code,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return InvestmentType(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get icon => iconDataFromName(iconName);
  Color get color => Color(0xFF000000 | int.parse(colorHex, radix: 16));

  static IconData iconDataFromName(String name) {
    return investmentIcons[name] ?? Icons.trending_up;
  }

  static String iconNameFromData(IconData icon) {
    for (final entry in investmentIcons.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return 'trending_up';
  }

  static const Map<String, IconData> investmentIcons = {
    'candlestick_chart': Icons.candlestick_chart,
    'currency_bitcoin': Icons.currency_bitcoin,
    'currency_exchange': Icons.currency_exchange,
    'diamond': Icons.diamond,
    'account_balance': Icons.account_balance,
    'article': Icons.article,
    'trending_up': Icons.trending_up,
    'more_horiz': Icons.more_horiz,
    'real_estate_agent': Icons.real_estate_agent,
    'gold': Icons.workspace_premium,
    'oil_barrel': Icons.oil_barrel,
    'agriculture': Icons.agriculture,
  };

  static const List<String> defaultColors = [
    '1976D2', // Blue
    'F7931A', // Bitcoin Orange
    '4CAF50', // Green
    'FFC107', // Amber
    '673AB7', // Deep Purple
    '795548', // Brown
    '607D8B', // Blue Grey
    'E91E63', // Pink
  ];
}

/// Varsayılan yatırım türleri
List<InvestmentType> getDefaultInvestmentTypes() {
  return [
    InvestmentType(
      name: 'Hisse Senedi',
      code: 'STOCK',
      iconName: 'candlestick_chart',
      colorHex: '1976D2',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Kripto Para',
      code: 'CRYPTO',
      iconName: 'currency_bitcoin',
      colorHex: 'F7931A',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Döviz',
      code: 'FOREX',
      iconName: 'currency_exchange',
      colorHex: '4CAF50',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Emtia',
      code: 'COMMODITY',
      iconName: 'diamond',
      colorHex: 'FFC107',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Fon',
      code: 'FUND',
      iconName: 'account_balance',
      colorHex: '673AB7',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Tahvil',
      code: 'BOND',
      iconName: 'article',
      colorHex: '795548',
      isDefault: true,
    ),
    InvestmentType(
      name: 'Diğer',
      code: 'OTHER',
      iconName: 'more_horiz',
      colorHex: '607D8B',
      isDefault: true,
    ),
  ];
}
