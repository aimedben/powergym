import 'package:flutter/material.dart';
import '../theme/sport_design.dart';

/// Compact horizontal stat card: icon left, value+label right.
class StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Colors.black.withValues(alpha: 0.45);
    final labelColor = Colors.white70;
    final borderColor = Colors.white.withValues(alpha: 0.10);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Value + Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontFamily: SportFonts.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: SportFonts.condensed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
