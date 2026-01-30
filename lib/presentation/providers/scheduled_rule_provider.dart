import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/scheduled_rule_repository.dart';
import '../../domain/entities/scheduled_rule.dart';

final scheduledRulesProvider = FutureProvider<List<ScheduledRule>>((ref) async {
  final repository = ref.watch(scheduledRuleRepositoryProvider);
  return repository.getAllRules();
});
