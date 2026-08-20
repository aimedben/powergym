import 'package:flutter/material.dart';
import '../theme/sport_design.dart';

/// Modern sporty section header with accent bar + condensed bold title
class SportSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accentColor;
  final Widget? trailing;

  const SportSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor = SportColors.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.white;

    return Row(
      children: [
        // Accent bar
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentColor, accentColor.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: accentColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: SportFonts.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
