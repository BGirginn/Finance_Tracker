import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/entities/ledger_entry.dart';

final ledgerEntriesProvider = FutureProvider<List<LedgerEntry>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getAllEntries();
});

final ledgerSearchProvider = StateProvider<String>((ref) => '');

final filteredLedgerEntriesProvider = FutureProvider<List<LedgerEntry>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  final searchQuery = ref.watch(ledgerSearchProvider);

  if (searchQuery.isEmpty) {
    return repository.getAllEntries();
  } else {
    return repository.searchEntries(searchQuery);
  }
});
