import 'package:flutter/material.dart';
import 'package:sportify_app/theme/app_theme.dart';

/// A button widget with neon purple glow effect when pressed
class NeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? glowColor;
  final double? borderRadius;
  final double? glowRadius;
  final bool isOutlined;

  const NeonButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.backgroundColor,
    this.glowColor,
    this.borderRadius,
    this.glowRadius,
    this.isOutlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _glowController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _glowController.reverse();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && widget.onPressed != null) {
          widget.onPressed!();
        }
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _glowController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? AppTheme.primary;
    final backgroundColor = widget.backgroundColor ?? AppTheme.primary;
    final borderRadius = widget.borderRadius ?? 16.0;
    final glowRadius = widget.glowRadius ?? 20.0;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isOutlined
                  ? (widget.backgroundColor ?? AppTheme.bgStart) // Use provided background or default to opaque
                  : (_isPressed ? backgroundColor.withValues(alpha: 0.9) : backgroundColor),
              borderRadius: BorderRadius.circular(borderRadius),
              border: widget.isOutlined
                  ? Border.all(
                      color: glowColor,
                      width: 2,
                    )
                  : null,
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.6 * _glowAnimation.value),
                        blurRadius: glowRadius * _glowAnimation.value,
                        spreadRadius: 4 * _glowAnimation.value,
                      ),
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.3 * _glowAnimation.value),
                        blurRadius: (glowRadius * 2) * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

