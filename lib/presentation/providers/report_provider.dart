import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../core/utils/date_utils.dart';

class ReportPeriod {
  final DateTime start;
  final DateTime end;
  final String type; // 'calendar' or 'custom'
  final int? cutDay;

  ReportPeriod({
    required this.start,
    required this.end,
    required this.type,
    this.cutDay,
  });
}

class ReportData {
  final Decimal incomeTotal;
  final Decimal expenseTotal;
  final Decimal net;
  final Map<String, Decimal> categoryBreakdown;

  ReportData({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.net,
    required this.categoryBreakdown,
  });
}

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  final now = DateTime.now();
  return ReportPeriod(
    start: DateUtils.getPeriodStart(now, 15),
    end: DateUtils.getPeriodEnd(now, 15),
    type: 'custom',
    cutDay: 15,
  );
});

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  final period = ref.watch(reportPeriodProvider);

  final entries = await repository.getEntriesByDateRange(period.start, period.end);

  Decimal incomeTotal = Decimal.zero;
  Decimal expenseTotal = Decimal.zero;
  final categoryBreakdown = <String, Decimal>{};

  for (final entry in entries) {
    if (entry.type == 'income') {
      incomeTotal += entry.amount;
    } else {
      expenseTotal += entry.amount;
      if (entry.category != null) {
        categoryBreakdown[entry.category!] =
            (categoryBreakdown[entry.category!] ?? Decimal.zero) + entry.amount;
      }
    }
  }

  return ReportData(
    incomeTotal: incomeTotal,
    expenseTotal: expenseTotal,
    net: incomeTotal - expenseTotal,
    categoryBreakdown: categoryBreakdown,
  );
});
