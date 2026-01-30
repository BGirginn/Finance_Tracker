import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dismissible (kaydırarak silinebilir) liste öğesi
class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final String deleteText;
  final String editText;

  const SwipeableListItem({
    super.key,
    required this.child,
    this.onDelete,
    this.onEdit,
    this.deleteText = 'Sil',
    this.editText = 'Düzenle',
  });

  @override
  Widget build(BuildContext context) {
    if (onDelete == null && onEdit == null) {
      return child;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: onDelete != null && onEdit != null
          ? DismissDirection.horizontal
          : (onDelete != null
              ? DismissDirection.endToStart
              : DismissDirection.startToEnd),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && onDelete != null) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Silme Onayı'),
              content: const Text('Bu öğeyi silmek istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Sil'),
                ),
              ],
            ),
          );
          if (result == true) {
            onDelete!();
          }
          return false; // Don't actually dismiss, we handle it ourselves
        } else if (direction == DismissDirection.startToEnd && onEdit != null) {
          onEdit!();
          return false;
        }
        return false;
      },
      background: onEdit != null
          ? Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    editText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : null,
      secondaryBackground: onDelete != null
          ? Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    deleteText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  const Icon(Icons.delete, color: Colors.white),
                ],
              ),
            )
          : null,
      child: child,
    );
  }
}

/// Animasyonlu liste öğesi
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}

/// Skeleton loading widget
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppTheme.darkDivider
        : AppTheme.lightDivider;
    final highlightColor = isDark
        ? AppTheme.darkSurface
        : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton kart - yükleme durumunda gösterilir
class SkeletonCard extends StatelessWidget {
  final int lines;

  const SkeletonCard({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCardColor
            : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(height: 16, width: 120),
                    SizedBox(height: AppTheme.spacingSm),
                    SkeletonLoader(height: 12, width: 80),
                  ],
                ),
              ),
            ],
          ),
          if (lines > 1) ...[
            const SizedBox(height: AppTheme.spacingMd),
            for (int i = 0; i < lines - 1; i++) ...[
              SkeletonLoader(height: 12, width: i == lines - 2 ? 160 : double.infinity),
              if (i < lines - 2) const SizedBox(height: AppTheme.spacingSm),
            ],
          ],
        ],
      ),
    );
  }
}
