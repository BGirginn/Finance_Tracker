import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/safe_bottom_padding.dart';
import '../../providers/investment_provider.dart';
import 'add_investment_screen.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen>
  with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(investmentPositionsProvider);
    final transactionsAsync = ref.watch(investmentTransactionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
              title: Text(
                'Yatırımlar',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                      builder: (context) => const AddInvestmentScreen(),
                    ),
                  );
                  ref.invalidate(investmentPositionsProvider);
                  ref.invalidate(investmentTransactionsProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkDivider.withValues(alpha: 0.3)
                      : AppTheme.lightDivider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Pozisyonlar'),
                    Tab(text: 'İşlemler'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPositionsTab(context, ref, positionsAsync),
            _buildTransactionsTab(context, ref, transactionsAsync),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddInvestmentScreen(),
            ),
          );
          ref.invalidate(investmentPositionsProvider);
          ref.invalidate(investmentTransactionsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('İşlem Ekle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPositionsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> positionsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(investmentPositionsProvider);
      },
      child: positionsAsync.when(
        data: (positions) {
          if (positions.isEmpty) {
            return EmptyState(
              icon: Icons.trending_up,
              title: 'Açık pozisyon yok',
              message: 'Yatırım işlemi ekleyerek portföyünüzü oluşturun.',
              actionLabel: 'İşlem Ekle',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddInvestmentScreen(),
                  ),
                );
                ref.invalidate(investmentPositionsProvider);
              },
            );
          }

          // Calculate totals
          final totalValue = positions.fold<Decimal>(
            Decimal.zero,
            (sum, p) => sum + (p.openQuantity * p.avgCost),
          );
          final totalPnL = positions.fold<Decimal>(
            Decimal.zero,
            (sum, p) => sum + p.realizedPnL,
          );

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // Portfolio Summary Card
              _buildPortfolioSummary(context, totalValue, totalPnL, positions.length),
              const SizedBox(height: AppTheme.spacingMd),
              // Position Cards
              ...positions.asMap().entries.map((entry) {
                return _PositionCard(
                  position: entry.value,
                  animationDelay: Duration(milliseconds: entry.key * 100),
                );
              }),
              // Dynamic bottom padding
              SafeBottomPadding(),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Pozisyonlar yükleniyor...'),
        error: (error, stack) => ErrorState(
          title: 'Yükleme hatası',
          message: error.toString(),
          onRetry: () => ref.invalidate(investmentPositionsProvider),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary(
    BuildContext context,
    Decimal totalValue,
    Decimal totalPnL,
    int positionCount,
  ) {
    final theme = Theme.of(context);
    final isPositive = totalPnL.compareTo(Decimal.zero) >= 0;

    return GradientCard(
      gradientColors: [
        AppTheme.primaryColor,
        AppTheme.secondaryColor,
      ],
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portföy Özeti',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '$positionCount pozisyon',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Toplam Değer',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            MoneyUtils.formatAmount(totalValue),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Gerçekleşen K/Z: ${isPositive ? '+' : ''}${MoneyUtils.formatAmount(totalPnL)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> transactionsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(investmentTransactionsProvider);
      },
      child: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long,
              title: 'Henüz işlem yok',
              message: 'İlk yatırım işleminizi ekleyin.',
              actionLabel: 'İşlem Ekle',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddInvestmentScreen(),
                  ),
                );
                ref.invalidate(investmentTransactionsProvider);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: transactions.length + 1, // +1 for bottom padding
            itemBuilder: (context, index) {
              if (index == transactions.length) {
                return SafeBottomPadding(); // Dynamic bottom padding
              }
              final transaction = transactions[index];
              return _TransactionCard(
                transaction: transaction,
                animationDelay: Duration(milliseconds: index * 80),
              );
            },
          );
        },
        loading: () => const LoadingState(message: 'İşlemler yükleniyor...'),
        error: (error, stack) => ErrorState(
          title: 'Yükleme hatası',
          message: error.toString(),
          onRetry: () => ref.invalidate(investmentTransactionsProvider),
        ),
      ),
    );
  }
}

class _PositionCard extends StatefulWidget {
  final dynamic position;
  final Duration animationDelay;

  const _PositionCard({
    required this.position,
    required this.animationDelay,
  });

  @override
  State<_PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends State<_PositionCard>
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
      begin: const Offset(0, 0.1),
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
    final position = widget.position;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = position.realizedPnL.compareTo(Decimal.zero) >= 0;
    final pnlColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: ModernCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.show_chart,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.asset,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          position.broker,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pnlColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: pnlColor,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          MoneyUtils.formatAmount(position.realizedPnL),
                          style: TextStyle(
                            color: pnlColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Miktar',
                        position.openQuantity.toString(),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Ort. Maliyet',
                        MoneyUtils.formatAmount(position.avgCost),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Toplam',
                        MoneyUtils.formatAmount(position.openQuantity * position.avgCost),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final dynamic transaction;
  final Duration animationDelay;

  const _TransactionCard({
    required this.transaction,
    required this.animationDelay,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

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
    final transaction = widget.transaction;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBuy = transaction.action.name == 'buy';
    final color = isBuy ? AppTheme.successColor : AppTheme.errorColor;
    final icon = isBuy ? Icons.south_west : Icons.north_east;

    return FadeTransition(
      opacity: _opacity,
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.broker} - ${transaction.asset}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.quantity} adet @ ${MoneyUtils.formatAmount(transaction.unitPrice, currency: transaction.currency)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app_date.DateUtils.formatDateTime(transaction.dateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                isBuy ? 'ALIŞ' : 'SATIŞ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
