import 'package:decimal/decimal.dart';

class PriceData {
  final Decimal bid;
  final Decimal ask;
  final DateTime timestamp;

  PriceData({
    required this.bid,
    required this.ask,
    required this.timestamp,
  });
}

abstract class PriceProvider {
  Future<PriceData?> fetchBidAsk(String broker, String asset);
}
