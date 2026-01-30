import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/investment_type.dart';
import '../../providers/investment_type_provider.dart';
import 'add_edit_investment_type_screen.dart';

class InvestmentTypesScreen extends ConsumerWidget {
  const InvestmentTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(investmentTypeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatırım Türleri'),
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(investmentTypeNotifierProvider.notifier).refresh(),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
        data: (types) {
          if (types.isEmpty) {
            return const Center(
              child: Text('Yatırım türü bulunamadı'),
            );
          }

          return ListView.builder(
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return _InvestmentTypeListTile(type: type);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addType(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addType(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditInvestmentTypeScreen(),
      ),
    );
  }
}

class _InvestmentTypeListTile extends ConsumerWidget {
  final InvestmentType type;

  const _InvestmentTypeListTile({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type.color.withValues(alpha: 0.2),
          child: Icon(
            type.icon,
            color: type.color,
          ),
        ),
        title: Text(type.name),
        subtitle: Text(type.code),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editType(context),
            ),
            if (!type.isDefault)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteType(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  void _editType(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditInvestmentTypeScreen(type: type),
      ),
    );
  }

  void _deleteType(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yatırım Türü Sil'),
        content: Text('${type.name} türünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(investmentTypeNotifierProvider.notifier).deleteType(type.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yatırım türü silindi')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
