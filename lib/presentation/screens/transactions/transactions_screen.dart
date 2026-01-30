import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/safe_bottom_padding.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/report_provider.dart';
import 'add_transaction_screen.dart';

// Filter state provider
final transactionFilterProvider = StateProvider<String>((ref) => 'all');

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(filteredLedgerEntriesProvider);
    final filter = ref.watch(transactionFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            title: Text(
              'İşlemler',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(),
                    ),
                  );
                  ref.invalidate(filteredLedgerEntriesProvider);
                  ref.invalidate(reportDataProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Search and Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'İşlem ara...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(ledgerSearchProvider.notifier).state = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingMd,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(ledgerSearchProvider.notifier).state = value;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tümü',
                          isSelected: filter == 'all',
                          onTap: () => ref.read(transactionFilterProvider.notifier).state = 'all',
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _FilterChip(
                          label: 'Gelirler',
                          isSelected: filter == 'income',
                          color: AppTheme.successColor,
                          icon: Icons.trending_up,
                          onTap: () => ref.read(transactionFilterProvider.notifier).state = 'income',
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _FilterChip(
                          label: 'Giderler',
                          isSelected: filter == 'expense',
                          color: AppTheme.errorColor,
                          icon: Icons.trending_down,
                          onTap: () => ref.read(transactionFilterProvider.notifier).state = 'expense',
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _FilterChip(
                          label: 'Planlı',
                          isSelected: filter == 'scheduled',
                          color: AppTheme.secondaryColor,
                          icon: Icons.schedule,
                          onTap: () => ref.read(transactionFilterProvider.notifier).state = 'scheduled',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List
          entriesAsync.when(
            data: (entries) {
              // Apply filter
              var filteredEntries = entries;
              if (filter == 'income') {
                filteredEntries = entries.where((e) => e.type == 'income').toList();
              } else if (filter == 'expense') {
                filteredEntries = entries.where((e) => e.type == 'expense').toList();
              } else if (filter == 'scheduled') {
                filteredEntries = entries.where((e) => e.source == 'scheduled').toList();
              }

              if (filteredEntries.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'İşlem bulunamadı',
                    message: filter == 'all'
                        ? 'Henüz hiç işlem eklenmemiş.'
                        : 'Bu filtreye uygun işlem yok.',
                    actionLabel: 'İşlem Ekle',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionScreen(),
                        ),
                      );
                      ref.invalidate(filteredLedgerEntriesProvider);
                      ref.invalidate(reportDataProvider);
                    },
                  ),
                );
              }

              // Group by date
              final groupedEntries = <String, List<dynamic>>{};
              for (final entry in filteredEntries) {
                final dateKey = app_date.DateUtils.formatDate(entry.date);
                groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dateKey = groupedEntries.keys.elementAt(index);
                    final dayEntries = groupedEntries[dateKey]!;
                    
                    return _DateSection(
                      date: dateKey,
                      entries: dayEntries,
                      animationController: _animationController,
                      index: index,
                      onRefresh: () => ref.invalidate(filteredLedgerEntriesProvider),
                    );
                  },
                  childCount: groupedEntries.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingState(message: 'İşlemler yükleniyor...'),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(
                title: 'Yükleme hatası',
                message: error.toString(),
                onRetry: () => ref.invalidate(filteredLedgerEntriesProvider),
              ),
            ),
          ),
          // Dynamic bottom padding for NavBar and FAB
          const SliverSafeBottomPadding(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          ref.invalidate(filteredLedgerEntriesProvider);
          ref.invalidate(reportDataProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni İşlem'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final String date;
  final List<dynamic> entries;
  final AnimationController animationController;
  final int index;
  final VoidCallback onRefresh;

  const _DateSection({
    required this.date,
    required this.entries,
    required this.animationController,
    required this.index,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
            child: Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...entries.asMap().entries.map((e) {
            return _TransactionListItem(
              entry: e.value,
              animationDelay: Duration(milliseconds: (index * 100) + (e.key * 50)),
              onRefresh: onRefresh,
            );
          }),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}

class _TransactionListItem extends ConsumerStatefulWidget {
  final dynamic entry;
  final Duration animationDelay;
  final VoidCallback onRefresh;

  const _TransactionListItem({
    required this.entry,
    required this.animationDelay,
    required this.onRefresh,
  });

  @override
  ConsumerState<_TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends ConsumerState<_TransactionListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = entry.type == 'income';
    final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;
    final icon = isIncome ? Icons.south_west : Icons.north_east;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Dismissible(
          key: Key('transaction_${entry.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppTheme.spacingMd),
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Sil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.delete_outline, color: Colors.white),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Silme Onayı'),
                content: const Text('Bu işlemi silmek istediğinizden emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (direction) async {
            try {
              final ledgerRepo = ref.read(ledgerRepositoryProvider);
              await ledgerRepo.deleteEntry(entry.id);
              // Refresh both transaction list and dashboard
              ref.invalidate(reportDataProvider);
              widget.onRefresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('İşlem silindi'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Geri Al',
                      onPressed: () {
                        // TODO: Implement undo
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            }
          },
          child: ModernCard(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            onTap: () {
              // TODO: Show edit dialog
            },
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.note.isNotEmpty ? entry.note : (isIncome ? 'Gelir' : 'Gider'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (entry.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.category!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (entry.source == 'scheduled')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 10,
                                    color: AppTheme.secondaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Planlı',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${MoneyUtils.formatAmount(entry.amount, currency: entry.currency)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
