import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/athlete_service.dart';
import '../models/subscription.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissed = (prefs.getStringList('dismissed_notifications') ?? []).toSet();
    });
  }

  Future<void> _dismissAll(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = notifications.map((n) => n['key'] as String).toList();
    setState(() => _dismissed.addAll(keys));
    await prefs.setStringList('dismissed_notifications', _dismissed.toList());
  }

  String _notifKey(Map<String, dynamic> n) {
    return '${n['athleteId']}_${n['type']}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<AthleteService>(
        builder: (context, athleteService, child) {
          final allNotifications = _buildNotifications(athleteService);
          final visible = allNotifications.where((n) => !_dismissed.contains(n['key'] as String)).toList();

          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All good!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No notifications right now.',
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white38 : const Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Clear All button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${visible.length}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'notification${visible.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Clear all?',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                )),
                            content: Text(
                              'This will dismiss ${visible.length} notification${visible.length > 1 ? 's' : ''}. New ones may appear if conditions persist.',
                              style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B))),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _dismissAll(visible);
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Notification list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final n = visible[index];
                    return _NotificationTile(
                      icon: n['icon'] as IconData,
                      title: n['title'] as String,
                      subtitle: n['subtitle'] as String,
                      color: n['color'] as Color,
                      time: n['time'] as String,
                      athleteId: n['athleteId'] as int?,
                      onDismiss: () async {
                        final prefs = await SharedPreferences.getInstance();
                        setState(() => _dismissed.add(n['key'] as String));
                        await prefs.setStringList('dismissed_notifications', _dismissed.toList());
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _buildNotifications(AthleteService service) {
    final notifications = <Map<String, dynamic>>[];

    for (final athlete in service.athletes) {
      if (athlete.id == null) continue;
      final sub = service.getLatestSubscription(athlete.id!);
      if (sub == null) continue;

      final now = DateTime.now();
      final daysLeft = sub.endDate.difference(now).inDays;

      // Expired
      if (sub.status == SubscriptionStatus.expired) {
        notifications.add({
          'key': '${athlete.id}_expired',
          'type': 'expired',
          'icon': Icons.cancel,
          'title': '${athlete.name} — Expired',
          'subtitle': 'Subscription ended on ${_formatDate(sub.endDate)}',
          'color': const Color(0xFFEF4444),
          'time': 'Expired',
          'athleteId': athlete.id,
        });
      }
      // Expiring within 3 days
      else if (sub.status == SubscriptionStatus.expiringSoon && daysLeft <= 3) {
        notifications.add({
          'key': '${athlete.id}_expiring3',
          'type': 'expiring3',
          'icon': Icons.warning,
          'title': '${athlete.name} — Expiring in $daysLeft days',
          'subtitle': 'Subscription ends on ${_formatDate(sub.endDate)}',
          'color': const Color(0xFFF59E0B),
          'time': '$daysLeft days left',
          'athleteId': athlete.id,
        });
      }
      // Expiring within 7 days
      else if (sub.status == SubscriptionStatus.expiringSoon) {
        notifications.add({
          'key': '${athlete.id}_expiring7',
          'type': 'expiring7',
          'icon': Icons.schedule,
          'title': '${athlete.name} — Expiring soon',
          'subtitle': 'Subscription ends on ${_formatDate(sub.endDate)}',
          'color': const Color(0xFFF59E0B),
          'time': '$daysLeft days left',
          'athleteId': athlete.id,
        });
      }
      // Unpaid
      if (!sub.isPaid) {
        notifications.add({
          'key': '${athlete.id}_unpaid',
          'type': 'unpaid',
          'icon': Icons.attach_money,
          'title': '${athlete.name} — Payment pending',
          'subtitle': '${sub.price.toStringAsFixed(0)} DA not paid',
          'color': const Color(0xFF8B5CF6),
          'time': 'Unpaid',
          'athleteId': athlete.id,
        });
      }
    }

    // Sort: expired first, then expiring, then unpaid
    notifications.sort((a, b) {
      final aColor = a['color'] as Color;
      final bColor = b['color'] as Color;
      if (aColor == const Color(0xFFEF4444) && bColor != const Color(0xFFEF4444)) return -1;
      if (aColor != const Color(0xFFEF4444) && bColor == const Color(0xFFEF4444)) return 1;
      return 0;
    });

    return notifications;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String time;
  final int? athleteId;
  final VoidCallback? onDismiss;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.time,
    this.athleteId,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('notif_${athleteId}_$title'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 24),
        ),
        child: Card(
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: athleteId != null
                ? () => Navigator.of(context, rootNavigator: true).pushNamed(
                      '/athlete-detail',
                      arguments: athleteId.toString(),
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}