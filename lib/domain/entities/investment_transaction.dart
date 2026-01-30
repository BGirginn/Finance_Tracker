import 'package:decimal/decimal.dart';

enum AssetType {
  stock,
  crypto,
  forex,
  commodity,
  other,
}

extension AssetTypeExtension on AssetType {
  String get displayName {
    switch (this) {
      case AssetType.stock:
        return 'Hisse Senedi';
      case AssetType.crypto:
        return 'Kripto Para';
      case AssetType.forex:
        return 'Döviz';
      case AssetType.commodity:
        return 'Emtia';
      case AssetType.other:
        return 'Diğer';
    }
  }

  String get code {
    switch (this) {
      case AssetType.stock:
        return 'STOCK';
      case AssetType.crypto:
        return 'CRYPTO';
      case AssetType.forex:
        return 'FOREX';
      case AssetType.commodity:
        return 'COMMODITY';
      case AssetType.other:
        return 'OTHER';
    }
  }

  static AssetType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'STOCK':
        return AssetType.stock;
      case 'CRYPTO':
        return AssetType.crypto;
      case 'FOREX':
        return AssetType.forex;
      case 'COMMODITY':
        return AssetType.commodity;
      default:
        return AssetType.other;
    }
  }
}

enum InvestmentAction {
  buy,
  sell,
}

class InvestmentTransaction {
  final int? id;
  final DateTime createdAt;
  final DateTime dateTime;
  final String broker;
  final String asset;
  final int? assetTypeId;
  final AssetType assetType; // Legacy - for backward compatibility
  final InvestmentAction action;
  final Decimal quantity;
  final Decimal unitPrice;
  final String currency;
  final Decimal fees; // Legacy total fees
  final String? notes;

  InvestmentTransaction({
    this.id,
    required this.createdAt,
    required this.dateTime,
    required this.broker,
    required this.asset,
    this.assetTypeId,
    required this.assetType,
    required this.action,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    Decimal? fees,
    this.notes,
  }) : fees = fees ?? Decimal.zero;

  Decimal get totalCost => (quantity * unitPrice) + fees;

  InvestmentTransaction copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? dateTime,
    String? broker,
    String? asset,
    int? assetTypeId,
    AssetType? assetType,
    InvestmentAction? action,
    Decimal? quantity,
    Decimal? unitPrice,
    String? currency,
    Decimal? fees,
    String? notes,
  }) {
    return InvestmentTransaction(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      dateTime: dateTime ?? this.dateTime,
      broker: broker ?? this.broker,
      asset: asset ?? this.asset,
      assetTypeId: assetTypeId ?? this.assetTypeId,
      assetType: assetType ?? this.assetType,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      fees: fees ?? this.fees,
      notes: notes ?? this.notes,
    );
  }
}

class InvestmentPosition {
  final String broker;
  final String asset;
  final Decimal openQuantity;
  final Decimal avgCost; // Including fees
  final Decimal realizedPnL;

  InvestmentPosition({
    required this.broker,
    required this.asset,
    required this.openQuantity,
    required this.avgCost,
    required this.realizedPnL,
  });
}
