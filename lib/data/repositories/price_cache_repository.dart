import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';

class PriceCache {
  final String broker;
  final String asset;
  final Decimal bid;
  final Decimal ask;
  final DateTime timestamp;

  PriceCache({
    required this.broker,
    required this.asset,
    required this.bid,
    required this.ask,
    required this.timestamp,
  });
}

class PriceCacheRepository {
  final AppDatabase _database;

  PriceCacheRepository(this._database);

  Future<PriceCache?> getCachedPrice(String broker, String asset) async {
    try {
      final cache = await (_database.select(_database.priceCaches)
            ..where((tbl) =>
                tbl.broker.equals(broker) & tbl.asset.equals(asset)))
          .getSingleOrNull();

      if (cache == null) return null;

      return PriceCache(
        broker: cache.broker,
        asset: cache.asset,
        bid: Decimal.parse(cache.bid),
        ask: Decimal.parse(cache.ask),
        timestamp: cache.timestamp,
      );
    } catch (e) {
      throw DatabaseException('Failed to get cached price: $e');
    }
  }

  Future<void> cachePrice(PriceCache priceCache) async {
    try {
      await _database.into(_database.priceCaches).insertOnConflictUpdate(
        PriceCachesCompanion(
          broker: Value(priceCache.broker),
          asset: Value(priceCache.asset),
          bid: Value(priceCache.bid.toString()),
          ask: Value(priceCache.ask.toString()),
          timestamp: Value(priceCache.timestamp),
        ),
      );
    } catch (e) {
      throw DatabaseException('Failed to cache price: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _database.delete(_database.priceCaches).go();
    } catch (e) {
      throw DatabaseException('Failed to clear price cache: $e');
    }
  }
}

final priceCacheRepositoryProvider = Provider<PriceCacheRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PriceCacheRepository(database);
});
