import 'dart:io';
import 'package:flutter/material.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../theme/sport_design.dart';
import 'subscription_status_badge.dart';

class AthleteCard extends StatelessWidget {
  final Athlete athlete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final SubscriptionStatus? subscriptionStatus;
  final bool isSelected;
  final bool isSelectionMode;

  const AthleteCard({
    super.key,
    required this.athlete,
    this.onTap,
    this.onLongPress,
    this.subscriptionStatus,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  bool get isFemale => athlete.gender == 'female';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = athlete.photoPath != null && athlete.photoPath!.isNotEmpty;
    final color = _getGenderColor();

    // Selection mode border color
    final borderColor = isSelected
        ? SportColors.primary
        : color.withValues(alpha: 0.15);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: borderColor,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            // Selection checkbox overlay (top-right corner)
            if (isSelectionMode)
              Positioned(
                top: 10,
                right: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? SportColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? SportColors.primary : (isDark ? Colors.white24 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),

            // Main content with left padding when in selection mode
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Selection mode left indicator
                  if (isSelectionMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? SportColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _buildAvatar(hasPhoto, color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                athlete.name,
                                style: TextStyle(
                                  fontFamily: SportFonts.condensed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : SportColors.textLight,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: isDark ? Colors.white24 : const Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(
                              athlete.phone.isNotEmpty ? athlete.phone : 'Pas de téléphone',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : SportColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (subscriptionStatus != null && !isSelectionMode) ...[
                    const SizedBox(width: 8),
                    SubscriptionStatusBadge(
                      status: subscriptionStatus!,
                      showPulse: subscriptionStatus == SubscriptionStatus.expired,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool hasPhoto, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.55)],
              ),
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(athlete.photoPath!)),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                _getInitials(athlete.name),
                style: const TextStyle(
                  fontFamily: SportFonts.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
    );
  }

  Color _getGenderColor() {
    if (isFemale) return SportColors.pink;
    return SportColors.primaryBright;
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
