import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = Colors.white.withValues(alpha: 0.08);
    final iconColor = Colors.white38;
    final textColor = Colors.white60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textColor, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
