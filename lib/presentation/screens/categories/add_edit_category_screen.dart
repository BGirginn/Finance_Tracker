import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/expense_category.dart';
import '../../providers/expense_category_provider.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final ExpenseCategory? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.iconName ?? 'category';
    _selectedColor = widget.category?.colorHex ?? ExpenseCategory.defaultColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Kategori Düzenle' : 'Yeni Kategori'),
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
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kategori adı gerekli';
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
    final icons = ExpenseCategory.categoryIcons.entries.toList();
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
        final color = Color(0xFF000000 | int.parse(_selectedColor, radix: 16));
        
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
      itemCount: ExpenseCategory.defaultColors.length,
      itemBuilder: (context, index) {
        final colorHex = ExpenseCategory.defaultColors[index];
        final color = Color(0xFF000000 | int.parse(colorHex, radix: 16));
        final isSelected = colorHex == _selectedColor;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorHex),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected 
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final color = Color(0xFF000000 | int.parse(_selectedColor, radix: 16));
    final icon = ExpenseCategory.iconDataFromName(_selectedIcon);
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _nameController.text.isEmpty ? 'Kategori Adı' : _nameController.text,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(expenseCategoryNotifierProvider.notifier);
      final category = ExpenseCategory(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        iconName: _selectedIcon,
        colorHex: _selectedColor,
        isDefault: widget.category?.isDefault ?? false,
        sortOrder: widget.category?.sortOrder ?? 0,
        createdAt: widget.category?.createdAt,
      );

      if (isEditing) {
        await notifier.updateCategory(category);
      } else {
        await notifier.addCategory(category);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Kategori güncellendi' : 'Kategori eklendi')),
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
