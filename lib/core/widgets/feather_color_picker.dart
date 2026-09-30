import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 笔记主题色选择器
class FeatherColorPicker extends StatelessWidget {
  final String selectedColorId;
  final ValueChanged<String> onColorSelected;

  const FeatherColorPicker({
    super.key,
    required this.selectedColorId,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: AppColors.noteColors.map((colorPreset) {
          final isSelected = colorPreset.id == selectedColorId;
          final bg = colorPreset.background(isDark);
          final border = colorPreset.border(isDark);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onColorSelected(colorPreset.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorPreset.accentColor : border,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorPreset.accentColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: colorPreset.accentColor,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
