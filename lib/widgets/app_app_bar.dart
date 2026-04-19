import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenu;
  final bool showBack;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenu = true,
    this.showBack = false,
    this.onMenuTap,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryRed,
      foregroundColor: AppTheme.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: AppTheme.white, size: 24),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackTap ?? () => Navigator.of(context).pop(),
            )
          : showMenu
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                )
              : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
