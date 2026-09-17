import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
    });
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isFocused;

    return Focus(
      focusNode: _focusNode,
      canRequestFocus: true,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF243F7C), Color(0xFF3B65B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected
                  ? null
                  : (_isFocused ? AppColors.surfaceElevated : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.cyanAccent
                    : (widget.isSelected
                        ? const Color(0xFF5B8DEF)
                        : AppColors.border),
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: (_isFocused
                                ? AppColors.cyanAccent
                                : AppColors.primaryGlow)
                            .withValues(alpha: _isFocused ? 0.6 : 0.4),
                        blurRadius: _isFocused ? 14 : 10,
                        spreadRadius: _isFocused ? 1.5 : 1,
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isSelected
                        ? Colors.white
                        : (_isFocused
                            ? AppColors.cyanAccent
                            : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : (_isFocused ? Colors.white : AppColors.textPrimary),
                    fontWeight: widget.isSelected || _isFocused
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
