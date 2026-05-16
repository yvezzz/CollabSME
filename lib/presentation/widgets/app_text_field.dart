import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final bool isPassword;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int? maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscure = false,
    this.isPassword = false,
    this.onToggleVisibility,
    this.validator,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.formatters,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _currentObscure;

  @override
  void initState() {
    super.initState();
    _currentObscure = widget.obscure;
  }

  void _toggleVisibility() {
    setState(() {
      _currentObscure = !_currentObscure;
    });
    if (widget.onToggleVisibility != null) {
      widget.onToggleVisibility!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _currentObscure,
      validator: widget.validator,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.formatters,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      style: TextStyle(color: widget.enabled ? Colors.white : Colors.white38),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        errorText: widget.errorText,
        prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(_currentObscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 20, color: AppColors.textSecondary),
                onPressed: _toggleVisibility,
              )
            : null,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger, width: 2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
