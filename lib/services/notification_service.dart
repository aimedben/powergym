import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../models/athlete.dart';
import '../models/subscription.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final DatabaseService _db = DatabaseService();

  bool _initialized = false;

  // ─── Channel IDs ──────────────────────────────────────────────

  static const String _channelReminders = 'subscription_reminders';
  static const String _channelExpired = 'subscription_expired';

  // ─── Notification ID Ranges ────────────────────────────────────
  //
  // Reminder IDs: athleteId * 10 + offset (0=7day, 1=3day, 2=1day)
  // Expired IDs:  athleteId * 10 + 3

  static int _reminderNotificationId(int athleteId, int offset) =>
      athleteId * 10 + offset;

  static int _expiredNotificationId(int athleteId) => athleteId * 10 + 3;

  // ─── Initialization ────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();

    _initialized = true;
  }

  // ─── Permission ────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return true;
  }

  // ─── Android Channels ──────────────────────────────────────────

  Future<void> _createNotificationChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const remindersChannel = AndroidNotificationChannel(
      _channelReminders,
      'Subscription Reminders',
      description: 'Reminders when a subscription is about to expire',
      importance: Importance.high,
      enableVibration: true,
    );

    const expiredChannel = AndroidNotificationChannel(
      _channelExpired,
      'Subscription Expired',
      description: 'Alerts when a subscription has expired',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
    );

    await android.createNotificationChannel(remindersChannel);
    await android.createNotificationChannel(expiredChannel);
  }

  // ─── Show Immediate Notification ───────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channel = _channelReminders,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      channel == _channelExpired ? 'Subscription Expired' : 'Subscription Reminders',
      channelDescription:
          channel == _channelExpired
              ? 'Alerts when a subscription has expired'
              : 'Reminders when a subscription is about to expire',
      importance: channel == _channelExpired ? Importance.max : Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF00E676),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  // ─── Schedule Expiry Reminders ─────────────────────────────────

  // Days before expiry to send reminders
  static const List<int> _reminderDays = [7, 3, 1];

  Future<void> scheduleExpiryReminders({
    required int athleteId,
    required String athleteName,
    required DateTime expiryDate,
  }) async {
    await cancelAthleteNotifications(athleteId);

    final now = DateTime.now();
    final reminderTimes = <int, DateTime>{};

    for (final days in _reminderDays) {
      final reminderDate = expiryDate.subtract(Duration(days: days));

      if (reminderDate.isAfter(now)) {
        reminderTimes[days] = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9,
          0,
        );
      }
    }

    for (final entry in reminderTimes.entries) {
      final scheduledDate = entry.value;
      final offset = _daysToOffset(entry.key);
      final notificationId = _reminderNotificationId(athleteId, offset);
      final daysLeft = entry.key;

      final title = daysLeft == 1
          ? 'Subscription Expiring Tomorrow!'
          : 'Subscription Expiring in $daysLeft Days';

      final body = "$athleteName's subscription expires on "
          '${_formatDate(expiryDate)}. Renew to keep access.';

      await _scheduleNotification(
        id: notificationId,
        scheduledDate: scheduledDate,
        title: title,
        body: body,
        channel: _channelReminders,
      );
    }
  }

  // ─── Notify Expired ────────────────────────────────────────────

  Future<void> showExpiredNotification({
    required int athleteId,
    required String athleteName,
  }) async {
    final notificationId = _expiredNotificationId(athleteId);

    await showNotification(
      id: notificationId,
      title: 'Subscription Expired',
      body: "$athleteName's subscription has expired. "
          'Renew now to restore access.',
      channel: _channelExpired,
    );
  }

  // ─── Check All Expired ─────────────────────────────────────────

  Future<void> checkExpiredSubscriptions() async {
    final athletesWithStatus = await _db.getAllAthletesWithSubscriptions();

    for (final entry in athletesWithStatus) {
      final athlete = entry['athlete'] as Athlete;
      final subscription = entry['latestSubscription'] as Subscription?;

      if (athlete.id == null) continue;

      if (subscription == null) continue;

      if (subscription.status == SubscriptionStatus.expired) {
        await showExpiredNotification(
          athleteId: athlete.id!,
          athleteName: athlete.name,
        );
      }
    }
  }

  // ─── Schedule All for Athlete ──────────────────────────────────

  Future<void> scheduleForAthlete(Athlete athlete) async {
    if (athlete.id == null) return;

    final subscriptions = await _db.getSubscriptionsByAthleteId(athlete.id!);
    if (subscriptions.isEmpty) return;

    final activeOrExpiring = subscriptions.where(
      (s) => s.status == SubscriptionStatus.active ||
          s.status == SubscriptionStatus.expiringSoon,
    );

    for (final sub in activeOrExpiring) {
      await scheduleExpiryReminders(
        athleteId: athlete.id!,
        athleteName: athlete.name,
        expiryDate: sub.endDate,
      );
    }
  }

  // ─── Schedule Daily Expired Check (works when app is closed) ─────

  static const int _dailyCheckId = 99999;

  Future<void> scheduleDailyExpiredCheck() async {
    await _notifications.cancel(_dailyCheckId);

    final now = DateTime.now();
    final tomorrowMorning = DateTime(
      now.year, now.month, now.day + 1, 9, 0,
    );

    await _scheduleNotification(
      id: _dailyCheckId,
      scheduledDate: tomorrowMorning,
      title: 'Verification abonnements',
      body: 'Vérifiez les abonnements expires.',
      channel: _channelExpired,
    );
  }

  // ─── Schedule Expiry Notification on exact date (fires when app closed) ──

  Future<void> scheduleExpiryNotification({
    required int athleteId,
    required String athleteName,
    required DateTime expiryDate,
    required double price,
  }) async {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return;

    // Cancel previous for this athlete
    await _notifications.cancel(athleteId * 10 + 7);

    // Schedule notification on expiry day at 9 AM
    final scheduledDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9, 0,
    );

    if (scheduledDate.isAfter(now)) {
      await _scheduleNotification(
        id: athleteId * 10 + 7,
        scheduledDate: scheduledDate,
        title: 'Abonnement expire aujourd\'hui!',
        body: "$athleteName: votre abonnement expire aujourd'hui. "
            'Prix: ${price.toStringAsFixed(0)} DA. Renouvelez!',
        channel: _channelExpired,
      );
    }
  }

  // ─── Schedule All Expiry Notifications (call on every app launch) ──

  Future<void> scheduleAllExpiryNotifications() async {
    final athletesWithStatus = await _db.getAllAthletesWithSubscriptions();

    for (final entry in athletesWithStatus) {
      final athlete = entry['athlete'] as Athlete;
      final subscription = entry['latestSubscription'] as Subscription?;

      if (athlete.id == null || subscription == null) continue;

      // For active/expiring: schedule notification on expiry date
      if (subscription.status != SubscriptionStatus.expired) {
        await scheduleExpiryNotification(
          athleteId: athlete.id!,
          athleteName: athlete.name,
          expiryDate: subscription.endDate,
          price: subscription.price,
        );
      }
    }
  }

  // ─── Cancel ────────────────────────────────────────────────────

  Future<void> cancelAthleteNotifications(int athleteId) async {
    final ids = [
      _reminderNotificationId(athleteId, 0),
      _reminderNotificationId(athleteId, 1),
      _reminderNotificationId(athleteId, 2),
      _expiredNotificationId(athleteId),
    ];

    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ─── Pending ───────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ─── Callback ──────────────────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('[Notification] Tapped: id=${response.id} payload=${response.payload}');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    required String channel,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      channel,
      channel == _channelExpired ? 'Subscription Expired' : 'Subscription Reminders',
      channelDescription:
          channel == _channelExpired
              ? 'Alerts when a subscription has expired'
              : 'Reminders when a subscription is about to expire',
      importance: channel == _channelExpired ? Importance.max : Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF00E676),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _daysToOffset(int days) {
    switch (days) {
      case 7:
        return 0;
      case 3:
        return 1;
      case 1:
        return 2;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
