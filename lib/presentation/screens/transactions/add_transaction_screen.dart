import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/category_keywords.dart';
import '../../../core/utils/money_utils.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../../domain/entities/expense_category.dart';
import '../../../data/repositories/ledger_repository.dart';
import '../../providers/report_provider.dart';
import '../../providers/expense_category_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.entry, this.initialType});

  final LedgerEntry? entry;
  final String? initialType; // 'income' or 'expense'

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  String _currency = 'TRY';
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final entry = widget.entry!;
      _type = entry.type;
      _currency = entry.currency;
      _amountController.text = entry.amount.toString();
      _noteController.text = entry.note;
      _selectedDate = entry.date;
      // Category will be set after categories load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCategoryFromEntry(entry.category, entry.type);
      });
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  void _loadCategoryFromEntry(String? categoryName, String? type) {
    if (categoryName == null) return;
    if (type == 'income') {
      final categories = ref.read(incomeCategoriesProvider);
      final match = categories.where((c) => c.name == categoryName).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _selectedCategory = match;
        });
      }
      return;
    }

    final categoriesAsync = ref.read(expenseCategoriesProvider);
    categoriesAsync.whenData((categories) {
      final match = categories.where((c) => c.name == categoryName).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _selectedCategory = match;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _suggestCategory(List<ExpenseCategory> categories) {
    final note = _noteController.text;
    if (note.isNotEmpty) {
      final categoryName = CategoryKeywords.suggestCategory(note);
      if (categoryName != null) {
        final match = categories.where((c) => c.name == categoryName).firstOrNull;
        if (match != null) {
          setState(() {
            _selectedCategory = match;
          });
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(ledgerRepositoryProvider);
      final amount = MoneyUtils.parseDecimal(_amountController.text);

      final entry = LedgerEntry(
        id: widget.entry?.id,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        date: _selectedDate,
        type: _type,
        amount: amount,
        currency: _currency,
        category: _selectedCategory?.name,
        note: _noteController.text,
        source: widget.entry?.source ?? 'manual',
      );

      if (widget.entry == null) {
        await repository.insertEntry(entry);
      } else {
        await repository.updateEntry(entry);
      }

      // Invalidate providers to refresh dashboard and transaction list
      ref.invalidate(reportDataProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expenseCategoriesProvider);
    final incomeList = ref.watch(incomeCategoriesProvider);
    final categoriesAsync = _type == 'expense' ? expenseAsync : AsyncValue.data(incomeList);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Yeni İşlem' : 'İşlem Düzenle'),
      ),
      body: categoriesAsync.when(
        data: (categories) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Gider')),
                  ButtonSegment(value: 'income', label: Text('Gelir')),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  border: OutlineInputBorder(),
                  prefixText: '₺ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tutar gerekli';
                  }
                  try {
                    MoneyUtils.parseDecimal(value);
                    return null;
                  } catch (e) {
                    return 'Geçersiz tutar';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not (Zorunlu)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
                enableSuggestions: true,
                autocorrect: true,
                onChanged: (_) => _suggestCategory(categories),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Not gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category Dropdown
              _buildCategorySelector(categories, theme),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tarih'),
                subtitle: Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  Widget _buildCategorySelector(List<ExpenseCategory> categories, ThemeData theme) {
    return InkWell(
      onTap: () => _showCategoryPicker(categories),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (_selectedCategory != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedCategory!.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedCategory!.icon,
                  color: _selectedCategory!.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCategory!.name,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ] else ...[
              Icon(
                Icons.category_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kategori seçin',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(List<ExpenseCategory> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Kategori Seçin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory?.id == category.id;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? category.color.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: category.color, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : null,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
