import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/investment_type.dart';
import '../../providers/investment_type_provider.dart';

class AddEditInvestmentTypeScreen extends ConsumerStatefulWidget {
  final InvestmentType? type;

  const AddEditInvestmentTypeScreen({super.key, this.type});

  @override
  ConsumerState<AddEditInvestmentTypeScreen> createState() => _AddEditInvestmentTypeScreenState();
}

class _AddEditInvestmentTypeScreenState extends ConsumerState<AddEditInvestmentTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  bool get isEditing => widget.type != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.type?.name ?? '');
    _codeController = TextEditingController(text: widget.type?.code ?? '');
    _selectedIcon = widget.type?.iconName ?? 'trending_up';
    _selectedColor = widget.type?.colorHex ?? InvestmentType.defaultColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Yatırım Türü Düzenle' : 'Yeni Yatırım Türü'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tür Adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tür adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Code field
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Kod',
                hintText: 'Örn: STOCK, CRYPTO',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kod gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Icon selection
            const Text(
              'İkon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildIconGrid(),
            const SizedBox(height: 24),

            // Color selection
            const Text(
              'Renk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildColorGrid(),
            const SizedBox(height: 32),

            // Preview
            const Text(
              'Önizleme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildPreview(),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Güncelle' : 'Kaydet'),
              ),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final entry = icons[index];
        final isSelected = entry.key == _selectedIcon;
        final color = Color(int.parse(_selectedColor, radix: 16));

        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = entry.key),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(
              entry.value,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: InvestmentType.defaultColors.length,
      itemBuilder: (context, index) {
        final colorHex = InvestmentType.defaultColors[index];
        final color = Color(int.parse(colorHex, radix: 16));
        final isSelected = colorHex == _selectedColor;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorHex),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final color = Color(int.parse(_selectedColor, radix: 16));
    final icon = InvestmentType.iconDataFromName(_selectedIcon);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _nameController.text.isEmpty ? 'Tür Adı' : _nameController.text,
        ),
        subtitle: Text(
          _codeController.text.isEmpty ? 'KOD' : _codeController.text.toUpperCase(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(investmentTypeNotifierProvider.notifier);
      final type = InvestmentType(
        id: widget.type?.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        iconName: _selectedIcon,
        colorHex: _selectedColor,
        isDefault: widget.type?.isDefault ?? false,
        createdAt: widget.type?.createdAt,
      );

      if (isEditing) {
        await notifier.updateType(type);
      } else {
        await notifier.addType(type);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Yatırım türü güncellendi' : 'Yatırım türü eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
