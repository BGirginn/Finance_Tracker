import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../domain/entities/expense_category.dart';
import '../../providers/expense_category_provider.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoryNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Kategorileri'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingState(message: 'Kategoriler yükleniyor...'),
        error: (error, stack) => ErrorState(
          title: 'Yükleme hatası',
          message: error.toString(),
          onRetry: () => ref.read(expenseCategoryNotifierProvider.notifier).refresh(),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'Kategori bulunamadı',
              message: 'Yeni kategori ekleyerek başlayın.',
              actionLabel: 'Kategori Ekle',
              onAction: () => _addCategory(context),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final items = List<ExpenseCategory>.from(categories);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              // Update sort orders
              for (int i = 0; i < items.length; i++) {
                await ref.read(expenseCategoryNotifierProvider.notifier).updateCategory(
                  items[i].copyWith(sortOrder: i),
                );
              }
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryListTile(
                key: ValueKey(category.id),
                category: category,
                index: index,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _addCategory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditCategoryScreen(),
      ),
    );
  }
}

class _CategoryListTile extends ConsumerStatefulWidget {
  final ExpenseCategory category;
  final int index;

  const _CategoryListTile({
    super.key,
    required this.category,
    required this.index,
  });

  @override
  ConsumerState<_CategoryListTile> createState() => _CategoryListTileState();
}

class _CategoryListTileState extends ConsumerState<_CategoryListTile>
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
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
    final category = widget.category;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: ModernCard(
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: Icon(
                    Icons.drag_handle,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                ),
              ),
              // Icon
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    if (category.isDefault)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Varsayılan',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => _editCategory(context),
                tooltip: 'Düzenle',
              ),
              if (!category.isDefault)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _deleteCategory(context, ref),
                  tooltip: 'Sil',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCategory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: widget.category),
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Kategori Sil'),
        content: Text('${widget.category.name} kategorisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(expenseCategoryNotifierProvider.notifier).deleteCategory(widget.category.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Kategori silindi'),
                        ],
                      ),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
