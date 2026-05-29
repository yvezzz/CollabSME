import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'country_picker_widget.dart';

class CityPickerWidget extends StatelessWidget {
  final String? country;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const CityPickerWidget({
    super.key,
    required this.country,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  List<String>? get _cities => country != null ? citiesByCountry[country] : null;

  @override
  Widget build(BuildContext context) {
    final cities = _cities;
    if (cities == null || cities.isEmpty) {
      return TextField(
        controller: TextEditingController(text: value ?? ''),
        enabled: enabled,
        style: TextStyle(color: enabled ? Colors.white : Colors.white38),
        decoration: InputDecoration(
          labelText: "Ville",
          prefixIcon: const Icon(LucideIcons.map, size: 20, color: AppColors.textSecondary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.card),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: enabled ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
          labelStyle: TextStyle(color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.4)),
        ),
        onChanged: (v) => onChanged(v),
      );
    }

    return DropdownButtonFormField<String>(
      value: value != null && cities.contains(value!) ? value : null,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: "Ville",
        prefixIcon: const Icon(LucideIcons.map, size: 20, color: AppColors.textSecondary),
        labelStyle: TextStyle(color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.card),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
      ),
      dropdownColor: AppColors.card,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      isExpanded: true,
      items: cities.map((c) {
        return DropdownMenuItem(value: c, child: Text(c));
      }).toList(),
      selectedItemBuilder: (context) {
        return cities.map((c) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(c, style: TextStyle(color: enabled ? Colors.white : Colors.white38)),
          );
        }).toList();
      },
    );
  }
}
