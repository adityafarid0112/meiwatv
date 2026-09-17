import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Reusable widget for TV remote control and touch/mouse interaction
class TvFocusableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? focusedBorderColor;
  final Color? focusedBackgroundColor;
  final bool autoScroll;
  final String? tooltip;

  const TvFocusableButton({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.padding,
    this.focusedBorderColor,
    this.focusedBackgroundColor,
    this.autoScroll = false,
    this.tooltip,
  });

  @override
  State<TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<TvFocusableButton> {
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
    if (focused && widget.autoScroll && mounted) {
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
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    Widget result = Focus(
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
        borderRadius: radius,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: _isFocused
                  ? (widget.focusedBackgroundColor ??
                      AppColors.primary.withValues(alpha: 0.2))
                  : Colors.transparent,
              border: Border.all(
                color: _isFocused
                    ? (widget.focusedBorderColor ?? AppColors.cyanAccent)
                    : Colors.transparent,
                width: _isFocused ? 2.2 : 0.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: (widget.focusedBorderColor ?? AppColors.cyanAccent)
                            .withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip!,
        child: result,
      );
    }

    return result;
  }
}
