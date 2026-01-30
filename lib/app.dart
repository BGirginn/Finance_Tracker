import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/ledger_provider.dart';
import 'presentation/providers/investment_provider.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/transactions/transactions_screen.dart';
import 'presentation/screens/transactions/add_transaction_screen.dart';
import 'presentation/screens/investments/investments_screen.dart';
import 'presentation/screens/investments/add_investment_screen.dart';
import 'presentation/screens/scheduled_rules/scheduled_rules_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Finance App',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> 
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFabExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const InvestmentsScreen(),
    const ScheduledRulesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _fabAnimationController.reverse();
      });
    }
  }

  void _addIncome() async {
    _closeFab();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(initialType: 'income'),
      ),
    );
    // Refresh data
    ref.invalidate(reportDataProvider);
    ref.invalidate(filteredLedgerEntriesProvider);
  }

  void _addExpense() async {
    _closeFab();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(initialType: 'expense'),
      ),
    );
    // Refresh data
    ref.invalidate(reportDataProvider);
    ref.invalidate(filteredLedgerEntriesProvider);
  }

  void _addInvestment() async {
    _closeFab();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddInvestmentScreen(),
      ),
    );
    // Refresh data
    ref.invalidate(investmentPositionsProvider);
    ref.invalidate(investmentTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[_currentIndex],
          ),
          // Dark overlay when FAB is expanded
          if (_isFabExpanded)
            GestureDetector(
              onTap: _closeFab,
              child: AnimatedBuilder(
                animation: _fabAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.5 * _fabAnimation.value),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _buildExpandableFab(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'İşlemler',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'Yatırımlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Planlı',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFab(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expandable menu items
        AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Investment option
                _buildFabMenuItem(
                  label: 'Yatırım',
                  icon: Icons.trending_up,
                  color: AppTheme.secondaryColor,
                  onTap: _addInvestment,
                  index: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                // Expense option
                _buildFabMenuItem(
                  label: 'Gider',
                  icon: Icons.arrow_downward,
                  color: AppTheme.errorColor,
                  onTap: _addExpense,
                  index: 1,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                // Income option
                _buildFabMenuItem(
                  label: 'Gelir',
                  icon: Icons.arrow_upward,
                  color: AppTheme.successColor,
                  onTap: _addIncome,
                  index: 0,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: AppTheme.primaryColor,
          elevation: 6,
          child: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _fabAnimation.value * 0.785398, // 45 degrees in radians
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int index,
    required bool isDark,
  }) {
    // Stagger the animation based on index
    final delay = index * 0.1;
    final itemAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Interval(delay, 0.6 + delay, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - itemAnimation.value)),
          child: Opacity(
            opacity: itemAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Mini FAB
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: color,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
