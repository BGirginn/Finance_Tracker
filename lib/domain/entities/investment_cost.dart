import 'package:decimal/decimal.dart';

enum InvestmentCostType {
  commission,  // Komisyon
  stampTax,    // Damga vergisi
  bsmv,        // BSMV
  custody,     // Saklama ücreti
  transfer,    // Transfer ücreti
  other,       // Diğer
}

extension InvestmentCostTypeExtension on InvestmentCostType {
  String get displayName {
    switch (this) {
      case InvestmentCostType.commission:
        return 'Komisyon';
      case InvestmentCostType.stampTax:
        return 'Damga Vergisi';
      case InvestmentCostType.bsmv:
        return 'BSMV';
      case InvestmentCostType.custody:
        return 'Saklama Ücreti';
      case InvestmentCostType.transfer:
        return 'Transfer Ücreti';
      case InvestmentCostType.other:
        return 'Diğer';
    }
  }

  String get code {
    switch (this) {
      case InvestmentCostType.commission:
        return 'commission';
      case InvestmentCostType.stampTax:
        return 'stamp_tax';
      case InvestmentCostType.bsmv:
        return 'bsmv';
      case InvestmentCostType.custody:
        return 'custody';
      case InvestmentCostType.transfer:
        return 'transfer';
      case InvestmentCostType.other:
        return 'other';
    }
  }

  static InvestmentCostType fromCode(String code) {
    switch (code) {
      case 'commission':
        return InvestmentCostType.commission;
      case 'stamp_tax':
        return InvestmentCostType.stampTax;
      case 'bsmv':
        return InvestmentCostType.bsmv;
      case 'custody':
        return InvestmentCostType.custody;
      case 'transfer':
        return InvestmentCostType.transfer;
      default:
        return InvestmentCostType.other;
    }
  }
}

class InvestmentCost {
  final int? id;
  final int transactionId;
  final InvestmentCostType costType;
  final Decimal amount;
  final String currency;
  final String? note;
  final DateTime createdAt;

  InvestmentCost({
    this.id,
    required this.transactionId,
    required this.costType,
    required this.amount,
    this.currency = 'TRY',
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  InvestmentCost copyWith({
    int? id,
    int? transactionId,
    InvestmentCostType? costType,
    Decimal? amount,
    String? currency,
    String? note,
    DateTime? createdAt,
  }) {
    return InvestmentCost(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      costType: costType ?? this.costType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
