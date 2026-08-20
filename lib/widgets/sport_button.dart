import 'package:flutter/material.dart';
import '../theme/sport_design.dart';

/// Modern sporty button with gradient background, glow shadow,
/// condensed bold label and pressed-state scale animation.
class SportButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final bool fullWidth;
  final bool loading;
  final double height;
  final double radius;

  const SportButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = sportPrimaryGradient,
    this.fullWidth = true,
    this.loading = false,
    this.height = 52,
    this.radius = 16,
  });

  @override
  State<SportButton> createState() => _SportButtonState();
}

class _SportButtonState extends State<SportButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = widget.gradient.colors.first;

    Widget content = widget.loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: SportFonts.condensed,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onPressed == null ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.fullWidth ? 20 : 24),
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? LinearGradient(colors: [isDark ? Colors.white10 : Colors.black12, isDark ? Colors.white10 : Colors.black12])
                : widget.gradient,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: widget.onPressed == null
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: widget.onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isDark ? 0.45 : 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Small sporty pill button — used for compact actions
class SportChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;

  const SportChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = SportColors.primary,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B))),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: SportFonts.condensed,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
