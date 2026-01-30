import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/scheduled_rule.dart';
import '../../../core/utils/money_utils.dart';
import '../../../data/repositories/scheduled_rule_repository.dart';

class AddScheduledRuleScreen extends ConsumerStatefulWidget {
  const AddScheduledRuleScreen({super.key, this.rule});

  final ScheduledRule? rule;

  @override
  ConsumerState<AddScheduledRuleScreen> createState() => _AddScheduledRuleScreenState();
}

class _AddScheduledRuleScreenState extends ConsumerState<AddScheduledRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteTemplateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _timeController = TextEditingController();

  String _type = 'expense';
  String _currency = 'TRY';
  int _dayOfMonth = 15;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      final rule = widget.rule!;
      _type = rule.type;
      _currency = rule.currency;
      _amountController.text = rule.amount.toString();
      _noteTemplateController.text = rule.noteTemplate;
      _categoryController.text = rule.category ?? '';
      _dayOfMonth = rule.dayOfMonth ?? 15;
      final timeParts = rule.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _timeController.text = rule.time;
    } else {
      _timeController.text = '12:00';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteTemplateController.dispose();
    _categoryController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(scheduledRuleRepositoryProvider);
      final amount = MoneyUtils.parseDecimal(_amountController.text);

      final rule = ScheduledRule(
        id: widget.rule?.id,
        enabled: widget.rule?.enabled ?? true,
        type: _type,
        amount: amount,
        currency: _currency,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        noteTemplate: _noteTemplateController.text,
        dayOfMonth: _dayOfMonth,
        time: _timeController.text,
        createdAt: widget.rule?.createdAt ?? DateTime.now(),
      );

      if (widget.rule == null) {
        await repository.insertRule(rule);
      } else {
        await repository.updateRule(rule);
      }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? 'Yeni Planlı İşlem' : 'Planlı İşlem Düzenle'),
      ),
      body: Form(
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
              controller: _noteTemplateController,
              decoration: const InputDecoration(
                labelText: 'Not Şablonu',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Not şablonu gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Ayın Günü: $_dayOfMonth'),
                ),
                Slider(
                  value: _dayOfMonth.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: _dayOfMonth.toString(),
                  onChanged: (value) {
                    setState(() {
                      _dayOfMonth = value.toInt();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Saat',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: _selectTime,
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
    );
  }
}
