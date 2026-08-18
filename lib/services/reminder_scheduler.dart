import '../models/athlete.dart';
import '../models/subscription.dart';
import 'database_service.dart';
import 'notification_service.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._();

  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();

  // Days before expiry to send reminders
  static const List<int> _reminderDays = [7, 3, 1];

  // ─── Calculate Reminder Schedule ───────────────────────────────
  //
  // Returns a map of {daysBeforeExpiry: scheduledDateTime}
  // Only includes future dates.

  Map<int, DateTime> calculateReminderTimes(DateTime expiryDate) {
    final now = DateTime.now();
    final result = <int, DateTime>{};

    for (final days in _reminderDays) {
      final reminderDate = expiryDate.subtract(Duration(days: days));

      if (reminderDate.isAfter(now)) {
        result[days] = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // Fire at 9:00 AM
          0,
        );
      }
    }

    return result;
  }

  // ─── Schedule All Reminders ────────────────────────────────────

  Future<void> scheduleForAllAthletes() async {
    final athletesWithStatus = await _db.getAllAthletesWithSubscriptions();

    for (final entry in athletesWithStatus) {
      final athlete = entry['athlete'] as Athlete;
      final subscription = entry['latestSubscription'] as Subscription?;

      if (athlete.id == null || athlete.isActive == false) continue;
      if (subscription == null) continue;
      if (subscription.status == SubscriptionStatus.expired) continue;

      await _notifications.scheduleExpiryReminders(
        athleteId: athlete.id!,
        athleteName: athlete.name,
        expiryDate: subscription.endDate,
      );
    }
  }

  // ─── On Subscription Renewed ───────────────────────────────────

  Future<void> onSubscriptionRenewed(Athlete athlete) async {
    if (athlete.id == null) return;

    await _notifications.cancelAthleteNotifications(athlete.id!);
    await _notifications.scheduleForAthlete(athlete);
  }

  // ─── On Athlete Deleted ────────────────────────────────────────

  Future<void> onAthleteDeleted(int athleteId) async {
    await _notifications.cancelAthleteNotifications(athleteId);
  }

  // ─── On App Launch ─────────────────────────────────────────────

  Future<void> refreshOnAppLaunch() async {
    await scheduleForAllAthletes();
    await _notifications.checkExpiredSubscriptions();
    // Schedule expiry notifications that fire even when app is closed
    await _notifications.scheduleAllExpiryNotifications();
  }
}
