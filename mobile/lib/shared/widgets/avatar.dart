import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Circular user avatar: shows a network image if [imageUrl] is set,
/// otherwise [initials] (e.g. a contact's first letter), otherwise a
/// fallback [icon]. Replaces the `CircleAvatar` variants duplicated across
/// profile, emergency contacts, and notifications.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.icon = Icons.person,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? imageUrl;
  final String? initials;
  final IconData icon;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.glassCyan20;
    final fg = foregroundColor ?? AppColors.accentCyan;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: bg, backgroundImage: NetworkImage(imageUrl!));
    }

    if (initials != null && initials!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          initials!,
          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: radius * 0.6),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(icon, color: fg, size: radius),
    );
  }
}
