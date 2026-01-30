import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/safe_bottom_padding.dart';
import '../../providers/report_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportDataAsync = ref.watch(reportDataProvider);
    final period = ref.watch(reportPeriodProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spacing = context.spacing;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
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
                  child: const Icon(Icons.notifications_outlined, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(reportDataProvider);
              },
                child: reportDataAsync.when(
                data: (data) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(context, ref, period),
                        SizedBox(height: context.spacing.md),
                        _buildQuickStats(context, data),
                        SizedBox(height: context.spacing.md),
                        _buildBalanceCard(context, data),
                      ],
                    ),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: LoadingState(message: 'Veriler yükleniyor...'),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: ErrorState(
                    title: 'Bir hata oluştu',
                    message: error.toString(),
                    onRetry: () => ref.invalidate(reportDataProvider),
                  ),
                ),
              ),
            ),
          ),
          // Category breakdown fills remaining space
          reportDataAsync.when(
            data: (data) => SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppTheme.spacingMd,
                  right: AppTheme.spacingMd,
                  bottom: AppTheme.spacingMd,
                ),
                child: _buildCategoryBreakdown(context, data),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın! ☀️';
    if (hour < 18) return 'İyi günler! 🌤️';
    return 'İyi akşamlar! 🌙';
  }

  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, ReportPeriod period) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
                padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              '${app_date.DateUtils.formatDate(period.start)} - ${app_date.DateUtils.formatDate(period.end)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showPeriodPicker(context, ref),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Değiştir'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.md),
              const Text(
                'Periyot Seçin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: context.spacing.md),
              _buildPeriodOption(context, ref, 'Bu Hafta', 'thisWeek'),
              _buildPeriodOption(context, ref, 'Bu Ay', 'thisMonth'),
              _buildPeriodOption(context, ref, 'Son 3 Ay', 'last3Months'),
              _buildPeriodOption(context, ref, 'Bu Yıl', 'thisYear'),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodOption(BuildContext context, WidgetRef ref, String label, String periodType) {
    return ListTile(
      leading: Icon(Icons.date_range, color: AppTheme.primaryColor),
      title: Text(label),
      onTap: () {
        final now = DateTime.now();
        DateTime start;
        DateTime end;
        
        switch (periodType) {
          case 'thisWeek':
            start = now.subtract(Duration(days: now.weekday - 1));
            end = start.add(const Duration(days: 6));
            break;
          case 'thisMonth':
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 0);
            break;
          case 'last3Months':
            start = DateTime(now.year, now.month - 2, 1);
            end = DateTime(now.year, now.month + 1, 0);
            break;
          case 'thisYear':
            start = DateTime(now.year, 1, 1);
            end = DateTime(now.year, 12, 31);
            break;
          default:
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 0);
        }
        
        ref.read(reportPeriodProvider.notifier).state = ReportPeriod(
          start: start,
          end: end,
          type: 'calendar',
        );
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ReportData data) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Gelir',
            value: MoneyUtils.formatAmount(data.incomeTotal),
            icon: Icons.trending_up,
            iconColor: AppTheme.successColor,
          ),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: StatCard(
            title: 'Gider',
            value: MoneyUtils.formatAmount(data.expenseTotal),
            icon: Icons.trending_down,
            iconColor: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, ReportData data) {
    final theme = Theme.of(context);
    final isPositive = data.net.compareTo(Decimal.zero) >= 0;

    return GradientCard(
      gradientColors: isPositive
          ? [const Color(0xFF10B981), const Color(0xFF059669)]
          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Bakiye',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Artı' : 'Eksi',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          Text(
            MoneyUtils.formatAmount(data.net),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Bu dönemdeki toplam bakiyeniz',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, ReportData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.categoryBreakdown.isEmpty) {
      return ModernCard(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'Kategori verisi yok',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Bu dönemde kategori kırılımı bulunmuyor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sortedCategories = data.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedCategories.fold<Decimal>(
      Decimal.zero,
      (sum, entry) => sum + entry.value,
    );

    return ModernCard(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Kırılımı',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                '${sortedCategories.length} kategori',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          // Categories list expands to fill remaining space
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final percentage = total > Decimal.zero
                    ? (entry.value.toDouble() / total.toDouble()) * 100.0
                    : 0.0;
                return _buildCategoryItem(context, entry.key, entry.value, percentage);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllCategories(
    BuildContext context,
    List<MapEntry<String, Decimal>> categories,
    Decimal total,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tüm Kategoriler',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${categories.length} kategori',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(context.spacing.md),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final entry = categories[index];
                    final percentage = total > Decimal.zero
                        ? (entry.value.toDouble() / total.toDouble()) * 100.0
                        : 0.0;
                    return _buildCategoryItem(context, entry.key, entry.value, percentage);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, Decimal amount, double percentage) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
    ];
    final colorIndex = name.hashCode % colors.length;

    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[colorIndex],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    MoneyUtils.formatAmount(amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors[colorIndex].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors[colorIndex],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: colors[colorIndex].withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colors[colorIndex]),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
