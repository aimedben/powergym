import 'package:flutter/material.dart';
import '../models/subscription.dart';

class SubscriptionStatusBadge extends StatefulWidget {
  final SubscriptionStatus status;
  final bool showPulse;
  final bool compact;

  const SubscriptionStatusBadge({
    super.key,
    required this.status,
    this.showPulse = false,
    this.compact = false,
  });

  @override
  State<SubscriptionStatusBadge> createState() => _SubscriptionStatusBadgeState();
}

class _SubscriptionStatusBadgeState extends State<SubscriptionStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.showPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SubscriptionStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.showPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    if (widget.compact) {
      return _buildCompactBadge(config);
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: config.color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.showPulse
              ? [
                  BoxShadow(
                    color: config.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 14,
              color: config.color,
            ),
            const SizedBox(width: 5),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: config.color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBadge(StatusConfig config) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: config.color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: widget.showPulse
              ? [
                  BoxShadow(
                    color: config.color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 12,
              color: config.color,
            ),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: config.color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusConfig _getStatusConfig() {
    switch (widget.status) {
      case SubscriptionStatus.active:
        return StatusConfig(
          label: 'Active',
          icon: Icons.check_circle,
          color: const Color(0xFF10B981), // Emerald
        );
      case SubscriptionStatus.expiringSoon:
        return StatusConfig(
          label: 'Expiring',
          icon: Icons.warning_amber,
          color: const Color(0xFFF59E0B), // Amber
        );
      case SubscriptionStatus.expired:
        return StatusConfig(
          label: 'Expired',
          icon: Icons.cancel,
          color: const Color(0xFFEF4444), // Red
        );
    }
  }
}

class StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  const StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
