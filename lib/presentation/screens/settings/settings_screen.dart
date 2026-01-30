import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/safe_bottom_padding.dart';
import '../../../services/backup/backup_service.dart';
import '../../providers/theme_provider.dart';
import '../categories/categories_screen.dart';
import '../investment_types/investment_types_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Ayarlar',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Görünüm Bölümü
                  _buildSectionTitle(context, 'Görünüm', Icons.palette_outlined),
                  const SizedBox(height: AppTheme.spacingSm),
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsListTile(
                          icon: currentThemeMode.icon,
                          iconColor: AppTheme.primaryColor,
                          title: 'Tema',
                          subtitle: currentThemeMode.displayName,
                          onTap: () => _showThemeDialog(context, ref, currentThemeMode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Kategoriler ve Türler Bölümü
                  _buildSectionTitle(context, 'Kategoriler ve Türler', Icons.category_outlined),
                  const SizedBox(height: AppTheme.spacingSm),
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsListTile(
                          icon: Icons.local_offer_outlined,
                          iconColor: AppTheme.successColor,
                          title: 'Harcama Kategorileri',
                          subtitle: 'Gelir ve gider kategorilerini yönetin',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                          indent: 56,
                        ),
                        _SettingsListTile(
                          icon: Icons.trending_up,
                          iconColor: AppTheme.infoColor,
                          title: 'Yatırım Türleri',
                          subtitle: 'Yatırım türlerini yönetin',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InvestmentTypesScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Genel Ayarlar Bölümü
                  _buildSectionTitle(context, 'Genel Ayarlar', Icons.tune_outlined),
                  const SizedBox(height: AppTheme.spacingSm),
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsListTile(
                          icon: Icons.currency_exchange,
                          iconColor: AppTheme.warningColor,
                          title: 'Varsayılan Para Birimi',
                          subtitle: 'TRY - Türk Lirası',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Text(
                              '₺',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ),
                          onTap: () => _showCurrencyDialog(context),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                          indent: 56,
                        ),
                        _SettingsListTile(
                          icon: Icons.calendar_month_outlined,
                          iconColor: AppTheme.secondaryColor,
                          title: 'Rapor Periyodu',
                          subtitle: '15→15 (Özel kesim günü)',
                          onTap: () => _showPeriodDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Veri Yönetimi Bölümü
                  _buildSectionTitle(context, 'Veri Yönetimi', Icons.storage_outlined),
                  const SizedBox(height: AppTheme.spacingSm),
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsListTile(
                          icon: Icons.cloud_upload_outlined,
                          iconColor: AppTheme.primaryColor,
                          title: 'Yedekle',
                          subtitle: 'Verilerinizi yedekleyin',
                          onTap: () => _createBackup(context, ref),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                          indent: 56,
                        ),
                        _SettingsListTile(
                          icon: Icons.cloud_download_outlined,
                          iconColor: AppTheme.successColor,
                          title: 'Geri Yükle',
                          subtitle: 'Yedekten geri yükleyin',
                          onTap: () => _restoreBackup(context, ref),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                          indent: 56,
                        ),
                        _SettingsListTile(
                          icon: Icons.download_outlined,
                          iconColor: AppTheme.infoColor,
                          title: 'CSV Dışa Aktar',
                          subtitle: 'İşlemleri CSV olarak dışa aktar',
                          onTap: () => _exportCsv(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Hakkında Bölümü
                  _buildSectionTitle(context, 'Hakkında', Icons.info_outline),
                  const SizedBox(height: AppTheme.spacingSm),
                  ModernCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsListTile(
                          icon: Icons.code,
                          iconColor: AppTheme.secondaryColor,
                          title: 'Versiyon',
                          subtitle: '1.0.0',
                          showChevron: false,
                        ),
                      ],
                    ),
                  ),
                  // Dynamic bottom padding
                  SafeBottomPadding(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeModeOption currentMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              const Text(
                'Tema Seçin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...ThemeModeOption.values.map((option) {
                final isSelected = option == currentMode;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : (isDark ? AppTheme.darkSurface : AppTheme.lightBackground),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      option.icon,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(option);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                );
              }),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = [
      ('TRY', 'Türk Lirası', '₺'),
      ('USD', 'ABD Doları', '\$'),
      ('EUR', 'Euro', '€'),
      ('GBP', 'İngiliz Sterlini', '£'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              const Text(
                'Para Birimi Seçin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...currencies.map((currency) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Center(
                        child: Text(
                          currency.$3,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ),
                    title: Text(currency.$1),
                    subtitle: Text(currency.$2),
                    trailing: currency.$1 == 'TRY'
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                        : null,
                    onTap: () {
                      // TODO: Save currency preference
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Periyot ayarları yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: ModernCard(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const Text('Yedekleniyor...'),
              ],
            ),
          ),
        ),
      );

      final backupService = ref.read(backupServiceProvider);
      final backupFile = await backupService.createBackup();

      if (context.mounted) {
        Navigator.pop(context);

        await Share.shareXFiles(
          [XFile(backupFile.path)],
          text: 'Finance App Backup',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Yedekleme başarılı'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('Geri Yükleme'),
          content: const Text('Mevcut verileri değiştirmek mi yoksa birleştirmek mi istersiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Birleştir'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
              child: const Text('Değiştir'),
            ),
          ],
        ),
      );

      if (replace == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: ModernCard(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text('Geri yükleniyor...'),
                ],
              ),
            ),
          ),
        );
      }

      final backupService = ref.read(backupServiceProvider);
      await backupService.restoreBackup(
        File(result.files.single.path!),
        replace: replace,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Geri yükleme başarılı'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV dışa aktarma yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
      ),
      trailing: trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                )
              : null),
      onTap: onTap,
    );
  }
}
