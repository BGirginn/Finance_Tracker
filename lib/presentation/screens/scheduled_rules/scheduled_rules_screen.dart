import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/safe_bottom_padding.dart';
import '../../../data/repositories/scheduled_rule_repository.dart';
import '../../providers/scheduled_rule_provider.dart';
import 'add_scheduled_rule_screen.dart';

class ScheduledRulesScreen extends ConsumerWidget {
  const ScheduledRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(scheduledRulesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Planlı İşlemler',
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
                      builder: (context) => const AddScheduledRuleScreen(),
                    ),
                  );
                  ref.invalidate(scheduledRulesProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(scheduledRulesProvider);
              },
              child: rulesAsync.when(
                data: (rules) {
                  if (rules.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: EmptyState(
                        icon: Icons.schedule_outlined,
                        title: 'Planlı işlem yok',
                        message: 'Düzenli gelir ve giderlerinizi ekleyin, otomatik kaydedilsin.',
                        actionLabel: 'Planlı İşlem Ekle',
                        onAction: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddScheduledRuleScreen(),
                            ),
                          );
                          ref.invalidate(scheduledRulesProvider);
                        },
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      children: [
                        // Stats card
                        _buildStatsCard(context, rules),
                        const SizedBox(height: AppTheme.spacingMd),
                        // Rules list
                        ...rules.asMap().entries.map((entry) {
                          return _ScheduledRuleCard(
                            rule: entry.value,
                            index: entry.key,
                            onRefresh: () => ref.invalidate(scheduledRulesProvider),
                          );
                        }),
                        // Dynamic bottom padding
                        SafeBottomPadding(),
                      ],
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const LoadingState(message: 'Yükleniyor...'),
                ),
                error: (error, stack) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ErrorState(
                    title: 'Yükleme hatası',
                    message: error.toString(),
                    onRetry: () => ref.invalidate(scheduledRulesProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddScheduledRuleScreen(),
            ),
          );
          ref.invalidate(scheduledRulesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, List<dynamic> rules) {
    final activeCount = rules.where((r) => r.enabled).length;
    final incomeCount = rules.where((r) => r.type == 'income').length;
    final expenseCount = rules.where((r) => r.type == 'expense').length;

    return ModernCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Toplam',
            value: rules.length.toString(),
            color: AppTheme.primaryColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkDivider
                : AppTheme.lightDivider,
          ),
          _StatItem(
            label: 'Aktif',
            value: activeCount.toString(),
            color: AppTheme.successColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkDivider
                : AppTheme.lightDivider,
          ),
          _StatItem(
            label: 'Gelir',
            value: incomeCount.toString(),
            color: AppTheme.successColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkDivider
                : AppTheme.lightDivider,
          ),
          _StatItem(
            label: 'Gider',
            value: expenseCount.toString(),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _ScheduledRuleCard extends ConsumerStatefulWidget {
  final dynamic rule;
  final int index;
  final VoidCallback onRefresh;

  const _ScheduledRuleCard({
    required this.rule,
    required this.index,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ScheduledRuleCard> createState() => _ScheduledRuleCardState();
}

class _ScheduledRuleCardState extends ConsumerState<_ScheduledRuleCard>
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
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
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
    final rule = widget.rule;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = rule.type == 'income';
    final color = rule.enabled
        ? (isIncome ? AppTheme.successColor : AppTheme.errorColor)
        : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary);
    final icon = isIncome ? Icons.south_west : Icons.north_east;

    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: ModernCard(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddScheduledRuleScreen(rule: rule),
              ),
            );
            widget.onRefresh();
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.noteTemplate,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          MoneyUtils.formatAmount(rule.amount, currency: rule.currency),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Her ayın ${rule.dayOfMonth}. günü',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Switch
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: rule.enabled,
                  activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return Colors.grey;
                  }),
                  onChanged: (value) async {
                    try {
                      final repository = ref.read(scheduledRuleRepositoryProvider);
                      await repository.updateRule(rule.copyWith(enabled: value));
                      widget.onRefresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
