import 'package:flutter/foundation.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../models/body_measurement.dart';
import 'database_service.dart';

class AthleteWithStatus {
  final Athlete athlete;
  final Subscription? activeSubscription;
  final SubscriptionStatus? subscriptionStatus;

  const AthleteWithStatus({
    required this.athlete,
    this.activeSubscription,
    this.subscriptionStatus,
  });

  bool get hasActiveSubscription => subscriptionStatus == SubscriptionStatus.active;
  bool get isExpiringSoon => subscriptionStatus == SubscriptionStatus.expiringSoon;
  bool get isExpired => subscriptionStatus == SubscriptionStatus.expired;
  bool get hasNoSubscription => activeSubscription == null;
}

class AthleteService extends ChangeNotifier {
  final DatabaseService _db;
  List<Athlete> _athletes = [];
  final Map<int, Subscription?> _latestSubscriptions = {};
  final Map<int, List<BodyMeasurement>> _measurementsByAthlete = {};

  AthleteService(this._db);

  List<Athlete> get athletes => List.unmodifiable(_athletes);

  List<BodyMeasurement>? getMeasurements(int athleteId) => _measurementsByAthlete[athleteId];

  Subscription? getLatestSubscription(int athleteId) => _latestSubscriptions[athleteId];

  SubscriptionStatus? getSubscriptionStatus(int athleteId) {
    final sub = _latestSubscriptions[athleteId];
    return sub?.status;
  }

  Map<String, int> getStats() {
    int active = 0;
    int expiring = 0;
    int expired = 0;

    for (final entry in _latestSubscriptions.entries) {
      final status = entry.value?.status;
      if (status == SubscriptionStatus.active) active++;
      if (status == SubscriptionStatus.expiringSoon) expiring++;
      if (status == SubscriptionStatus.expired) expired++;
    }

    return {
      'total': _athletes.length,
      'active': active,
      'expiring': expiring,
      'expired': expired,
    };
  }

  Future<void> loadAthletes() async {
    _athletes = await _db.getAllAthletes();
    await _loadSubscriptions();
    notifyListeners();
  }

  Future<void> _loadSubscriptions() async {
    _latestSubscriptions.clear();
    for (final athlete in _athletes) {
      if (athlete.id == null) continue;
      final subs = await _db.getSubscriptionsByAthleteId(athlete.id!);
      _latestSubscriptions[athlete.id!] = subs.isNotEmpty ? subs.first : null;
    }
  }

  Future<int> addAthlete(Athlete athlete) async {
    final id = await _db.insertAthlete(athlete);
    await loadAthletes();
    return id;
  }

  Future<void> updateAthlete(Athlete athlete) async {
    await _db.updateAthlete(athlete);
    await loadAthletes();
  }

  Future<void> deleteAthlete(int athleteId) async {
    await _db.deleteAthlete(athleteId);
    await loadAthletes();
  }

  Future<void> deleteSubscription(int subscriptionId) async {
    await _db.deleteSubscription(subscriptionId);
    await loadAthletes();
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _db.updateSubscription(subscription);
    await loadAthletes();
  }

  Athlete? getAthleteById(dynamic id) {
    final intId = id is String ? int.tryParse(id) : id as int?;
    if (intId == null) return null;
    try {
      return _athletes.firstWhere((a) => a.id == intId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Athlete>> searchAthletes(String query) async {
    if (query.trim().isEmpty) return _athletes;
    return await _db.searchAthletes(query.trim());
  }

  Future<int> addSubscription(Subscription subscription) async {
    final id = await _db.insertSubscription(subscription);
    await loadAthletes();
    return id;
  }

  Future<void> renewSubscription({
    required int athleteId,
    required SubscriptionType type,
    required double price,
    bool isPaid = false,
    String? notes,
  }) async {
    final now = DateTime.now();
    final endDate = _calculateEndDate(now, type);

    final subscription = Subscription(
      athleteId: athleteId,
      type: type,
      startDate: now,
      endDate: endDate,
      price: price,
      isPaid: isPaid,
      notes: notes,
    );

    await _db.insertSubscription(subscription);
    await loadAthletes();
  }

  DateTime _calculateEndDate(DateTime from, SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case SubscriptionType.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case SubscriptionType.semester:
        return DateTime(from.year, from.month + 6, from.day);
      case SubscriptionType.annual:
        return DateTime(from.year + 1, from.month, from.day);
      case SubscriptionType.custom:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  Future<void> deleteMultiple(List<int> athleteIds) async {
    for (final id in athleteIds) {
      await _db.deleteAthlete(id);
    }
    await loadAthletes();
  }

  Future<void> renewMultiple({
    required List<int> athleteIds,
    required SubscriptionType type,
    required double price,
    bool isPaid = false,
  }) async {
    final now = DateTime.now();
    final endDate = _calculateEndDate(now, type);

    for (final athleteId in athleteIds) {
      final subscription = Subscription(
        athleteId: athleteId,
        type: type,
        startDate: now,
        endDate: endDate,
        price: price,
        isPaid: isPaid,
      );
      await _db.insertSubscription(subscription);
    }
    await loadAthletes();
  }

  Future<List<AthleteWithStatus>> getAthletesWithStatus() async {
    final athletesWithSubs = await _db.getAllAthletesWithSubscriptions();
    return athletesWithSubs.map((entry) {
      final athlete = entry['athlete'] as Athlete;
      final latestSub = entry['latestSubscription'] as Subscription?;
      return AthleteWithStatus(
        athlete: athlete,
        activeSubscription: latestSub,
        subscriptionStatus: latestSub?.status,
      );
    }).toList();
  }

  // ─── Body Measurements ─────────────────────────────────────────

  Future<List<BodyMeasurement>> loadMeasurements(int athleteId) async {
    final measurements = await _db.getBodyMeasurementsByAthleteId(athleteId);
    _measurementsByAthlete[athleteId] = measurements;
    notifyListeners();
    return measurements;
  }

  Future<void> addMeasurement(BodyMeasurement measurement) async {
    await _db.insertBodyMeasurement(measurement);
    await loadMeasurements(measurement.athleteId);
  }

  Future<void> updateMeasurement(BodyMeasurement measurement) async {
    await _db.updateBodyMeasurement(measurement);
    await loadMeasurements(measurement.athleteId);
  }

  Future<void> deleteMeasurement(int measurementId, int athleteId) async {
    await _db.deleteBodyMeasurement(measurementId);
    await loadMeasurements(athleteId);
  }

  Future<void> _loadMeasurementsForAthlete(int athleteId) async {
    _measurementsByAthlete[athleteId] = await _db.getBodyMeasurementsByAthleteId(athleteId);
  }

  Future<void> loadAllMeasurements() async {
    for (final athlete in _athletes) {
      if (athlete.id != null) await _loadMeasurementsForAthlete(athlete.id!);
    }
    notifyListeners();
  }
}
