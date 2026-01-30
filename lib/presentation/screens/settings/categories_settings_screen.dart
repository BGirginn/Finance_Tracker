import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/add_edit_category_screen.dart';
import '../../../domain/entities/expense_category.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../providers/expense_category_provider.dart';

class CategoriesSettingsScreen extends ConsumerStatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  ConsumerState<CategoriesSettingsScreen> createState() => _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState extends ConsumerState<CategoriesSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expenseCategoryNotifierProvider);
    final incomeList = ref.watch(incomeCategoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler (Ayarlar)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Gider'), Tab(text: 'Gelir')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPressed(),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Expense tab
          expenseAsync.when(
            loading: () => const LoadingState(message: 'Yükleniyor...'),
            error: (e, _) => ErrorState(title: 'Hata', message: e.toString()),
            data: (categories) => _buildExpenseList(categories),
          ),
          // Income tab
          _buildIncomeList(incomeList),
          // Investment tab
          _buildInvestmentList(ref.watch(investmentTypeNotifierProvider)),
        ],
      ),
    );
  }

  Widget _buildInvestmentList(List<InvestmenTtypePlaceholder> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        return Padding(
          key: ValueKey(t.id),
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ModernCard(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFF000000 | int.parse(t.colorHex, radix: 16)).withOpacity(0.15), child: Icon(InvestmentType.iconDataFromName(t.iconName), color: Color(0xFF000000 | int.parse(t.colorHex, radix: 16)))),
              title: Text(t.name),
              subtitle: Text(t.code),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editInvestmentType(t)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteInvestmentType(t)),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _editInvestmentType(InvestmenTtypePlaceholder t) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AddEditInvestmentTypeScreen(type: t, onSave: (edited) async {
      await ref.read(investmentTypeNotifierProvider.notifier).updateType(edited);
    })));
  }

  void _deleteInvestmentType(InvestmenTtypePlaceholder t) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Sil'), content: Text('${t.name} silinsin mi?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await ref.read(investmentTypeNotifierProvider.notifier).deleteType(t.id); }, child: const Text('Sil'))]));
  }

  Widget _buildExpenseList(List<ExpenseCategory> categories) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        final items = List<ExpenseCategory>.from(categories);
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
        for (int i = 0; i < items.length; i++) {
          await ref.read(expenseCategoryNotifierProvider.notifier).updateCategory(items[i].copyWith(sortOrder: i));
        }
      },
      itemBuilder: (context, index) {
        final c = categories[index];
        return _settingsTile(key: ValueKey(c.id), category: c, isIncome: false);
      },
    );
  }

  Widget _buildIncomeList(List<ExpenseCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final c = categories[index];
        return _settingsTile(key: ValueKey(c.id ?? index), category: c, isIncome: true);
      },
    );
  }

  Widget _settingsTile({required Key key, required ExpenseCategory category, required bool isIncome}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ModernCard(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: category.color.withOpacity(0.15), child: Icon(category.icon, color: category.color)),
          title: Text(category.name),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editCategory(category, isIncome),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteCategory(category, isIncome),
            ),
          ]),
        ),
      ),
    );
  }

  void _onAddPressed() {
    final isIncome = _tabController.index == 1;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => AddEditCategoryScreen(
        onSave: (cat) async {
          if (isIncome) {
            await ref.read(incomeCategoryNotifierProvider.notifier).addCategory(cat);
          } else {
            await ref.read(expenseCategoryNotifierProvider.notifier).addCategory(cat);
          }
        },
      ),
    ));
  }

  void _editCategory(ExpenseCategory category, bool isIncome) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => AddEditCategoryScreen(
        category: category,
        onSave: (cat) async {
          if (isIncome) {
            await ref.read(incomeCategoryNotifierProvider.notifier).updateCategory(cat);
          } else {
            await ref.read(expenseCategoryNotifierProvider.notifier).updateCategory(cat);
          }
        },
      ),
    ));
  }

  void _deleteCategory(ExpenseCategory category, bool isIncome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Sil'),
        content: Text('${category.name} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isIncome) {
                if (category.id != null) await ref.read(incomeCategoryNotifierProvider.notifier).deleteCategory(category.id!);
                else await ref.read(incomeCategoryNotifierProvider.notifier).deleteCategory(category.hashCode);
              } else {
                await ref.read(expenseCategoryNotifierProvider.notifier).deleteCategory(category.id!);
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
