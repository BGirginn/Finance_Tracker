import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../../services/notification/notification_service.dart';
import '../../services/price/price_provider.dart';
import '../../services/price/html_price_provider.dart';
import '../../data/repositories/expense_category_repository.dart';
import '../../data/repositories/investment_type_repository.dart';
import '../../data/repositories/investment_cost_repository.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider must be overridden');
});

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Notification service provider must be overridden');
});

// Price Provider
final priceProviderProvider = Provider<PriceProvider>((ref) {
  return HtmlPriceProvider();
});

// Expense Category Repository Provider
final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ExpenseCategoryRepository(database);
});

// Investment Type Repository Provider
final investmentTypeRepositoryProvider = Provider<InvestmentTypeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return InvestmentTypeRepository(database);
});

// Investment Cost Repository Provider
final investmentCostRepositoryProvider = Provider<InvestmentCostRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return InvestmentCostRepository(database);
});
