import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Standard text input - wraps [TextFormField] with the app's usual
/// label/icon decoration (styling itself comes from the global
/// `inputDecorationTheme`) and a built-in obscure-text toggle, replacing
/// the `_obscurePassword` boolean + suffix `IconButton` that was
/// hand-rolled in both the login and register screens.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon != null ? Icon(widget.icon, color: AppColors.accentCyan) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
