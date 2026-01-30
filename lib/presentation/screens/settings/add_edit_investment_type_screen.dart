import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/investment_type.dart';
import '../../../domain/entities/expense_category.dart';

class AddEditInvestmentTypeScreen extends ConsumerStatefulWidget {
  final InvestmenTtypePlaceholder? type;
  final Future<void> Function(InvestmenTtypePlaceholder)? onSave;

  const AddEditInvestmentTypeScreen({super.key, this.type, this.onSave});

  @override
  ConsumerState<AddEditInvestmentTypeScreen> createState() => _AddEditInvestmentTypeScreenState();
}

class _AddEditInvestmentTypeScreenState extends ConsumerState<AddEditInvestmentTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _iconName;
  late String _colorHex;
  bool _isLoading = false;

  bool get isEditing => widget.type != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.type?.name ?? '');
    _iconName = widget.type?.iconName ?? InvestmentType.investmentIcons.keys.first;
    _colorHex = widget.type?.colorHex ?? InvestmentType.defaultColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Yatırım Türünü Düzenle' : 'Yeni Yatırım Türü')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: 16),
            const Text('İkon'),
            const SizedBox(height: 8),
            _buildIconGrid(),
            const SizedBox(height: 16),
            const Text('Renk'),
            const SizedBox(height: 8),
            _buildColorGrid(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid() {
    final icons = InvestmentType.investmentIcons.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final entry = icons[index];
        final isSelected = entry.key == _iconName;
        final color = Color(0xFF000000 | int.parse(_colorHex, radix: 16));
        return GestureDetector(
          onTap: () => setState(() => _iconName = entry.key),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.18) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(entry.value, color: isSelected ? color : Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: InvestmentType.defaultColors.length,
      itemBuilder: (context, index) {
        final hex = InvestmentType.defaultColors[index];
        final color = Color(0xFF000000 | int.parse(hex, radix: 16));
        final isSelected = hex == _colorHex;
        return GestureDetector(
          onTap: () => setState(() => _colorHex = hex),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final id = widget.type?.id ?? DateTime.now().millisecondsSinceEpoch;
    final placeholder = InvestmenTtypePlaceholder(id: id, name: _nameController.text.trim(), code: widget.type?.code ?? 'CUSTOM', iconName: _iconName, colorHex: _colorHex);

    try {
      if (widget.onSave != null) {
        await widget.onSave!(placeholder);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
