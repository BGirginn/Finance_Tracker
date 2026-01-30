import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/investment_transaction.dart';
import '../../../core/utils/money_utils.dart';
import '../../../data/repositories/investment_repository.dart';

class AddInvestmentScreen extends ConsumerStatefulWidget {
  const AddInvestmentScreen({super.key, this.transaction});

  final InvestmentTransaction? transaction;

  @override
  ConsumerState<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends ConsumerState<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brokerController = TextEditingController();
  final _assetController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _feesController = TextEditingController();
  final _notesController = TextEditingController();

  InvestmentAction _action = InvestmentAction.buy;
  AssetType _assetType = AssetType.other;
  String _currency = 'TRY';
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _brokerController.text = t.broker;
      _assetController.text = t.asset;
      _quantityController.text = t.quantity.toString();
      _unitPriceController.text = t.unitPrice.toString();
      _feesController.text = t.fees.toString();
      _notesController.text = t.notes ?? '';
      _action = t.action;
      _assetType = t.assetType;
      _currency = t.currency;
      _selectedDateTime = t.dateTime;
    } else {
      // BUG FIX: Set default value for fees in initState, not with initialValue
      _feesController.text = '0';
    }
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _assetController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _feesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(investmentRepositoryProvider);

      final transaction = InvestmentTransaction(
        id: widget.transaction?.id,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        dateTime: _selectedDateTime,
        broker: _brokerController.text,
        asset: _assetController.text,
        assetType: _assetType,
        action: _action,
        quantity: MoneyUtils.parseDecimal(_quantityController.text),
        unitPrice: MoneyUtils.parseDecimal(_unitPriceController.text),
        currency: _currency,
        fees: MoneyUtils.parseDecimal(_feesController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.transaction == null) {
        await repository.insertTransaction(transaction);
      } else {
        await repository.updateTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Yeni Yatırım' : 'Yatırım Düzenle'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // Action selector
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
              ),
              child: SegmentedButton<InvestmentAction>(
                segments: [
                  ButtonSegment(
                    value: InvestmentAction.buy,
                    label: const Text('Alış'),
                    icon: const Icon(Icons.south_west, size: 18),
                  ),
                  ButtonSegment(
                    value: InvestmentAction.sell,
                    label: const Text('Satış'),
                    icon: const Icon(Icons.north_east, size: 18),
                  ),
                ],
                selected: {_action},
                onSelectionChanged: (Set<InvestmentAction> newSelection) {
                  setState(() {
                    _action = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _action == InvestmentAction.buy
                          ? AppTheme.successColor
                          : AppTheme.errorColor;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            DropdownButtonFormField<AssetType>(
              value: _assetType,
              decoration: InputDecoration(
                labelText: 'Varlık Tipi',
                prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              items: AssetType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _assetType = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _brokerController,
              decoration: InputDecoration(
                labelText: 'Broker/Firma',
                prefixIcon: Icon(Icons.business_outlined, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Broker/Firma gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _assetController,
              decoration: InputDecoration(
                labelText: 'Varlık',
                prefixIcon: Icon(Icons.show_chart, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Varlık gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Miktar',
                      prefixIcon: Icon(Icons.numbers, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Miktar gerekli';
                      }
                      try {
                        MoneyUtils.parseDecimal(value);
                        return null;
                      } catch (e) {
                        return 'Geçersiz miktar';
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: InputDecoration(
                      labelText: 'Birim Fiyat',
                      prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Fiyat gerekli';
                      }
                      try {
                        MoneyUtils.parseDecimal(value);
                        return null;
                      } catch (e) {
                        return 'Geçersiz fiyat';
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _feesController,
              decoration: InputDecoration(
                labelText: 'Komisyon',
                prefixIcon: Icon(Icons.percent, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              // BUG FIX: Removed initialValue - using controller instead
            ),
            const SizedBox(height: AppTheme.spacingMd),
            InkWell(
              onTap: _selectDateTime,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarih ve Saat',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${_selectedDateTime.day}.${_selectedDateTime.month}.${_selectedDateTime.year} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notlar',
                prefixIcon: Icon(Icons.notes, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Text(
                'Kaydet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
