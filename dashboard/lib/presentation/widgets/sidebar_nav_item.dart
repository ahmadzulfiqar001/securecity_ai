import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../shell/nav_items.dart';

class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    super.key,
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.glassCyan10 : AppColors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.glassBorderCyan : AppColors.transparent),
      ),
      child: Row(
        mainAxisSize: collapsed ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: selected ? AppColors.accentCyan : AppColors.darkTextSecondary,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: collapsed ? item.label : '',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: content),
      ),
    );
  }
}
