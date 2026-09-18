import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVFocusableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final BorderRadius? borderRadius;
  final Color focusGlowColor;
  final bool autofocus;
  final FocusNode? focusNode;

  const TVFocusableWidget({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 1.05,
    this.borderRadius,
    this.focusGlowColor = const Color(0xFFA855F7),
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<TVFocusableWidget> createState() => _TVFocusableWidgetState();
}

class _TVFocusableWidgetState extends State<TVFocusableWidget> {
  late FocusNode _node;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.removeListener(_onFocusChange);
      _node.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _node.hasFocus;
    });

    if (_isFocused) {
      // Auto-scroll into view when focused by TV remote
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

    return FocusableActionDetector(
      focusNode: _node,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _isFocused ? widget.scaleFactor : 1.0,
            _isFocused ? widget.scaleFactor : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: widget.focusGlowColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _isFocused ? widget.focusGlowColor : Colors.transparent,
                width: _isFocused ? 2.5 : 0,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
