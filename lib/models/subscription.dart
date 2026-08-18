enum SubscriptionType {
  monthly,
  quarterly,
  semester,
  annual,
  custom,
}

enum SubscriptionStatus {
  active,
  expiringSoon,
  expired,
}

class Subscription {
  final int? id;
  final int athleteId;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final bool isPaid;
  final DateTime? paymentDate;
  final String? notes;

  const Subscription({
    this.id,
    required this.athleteId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.isPaid = false,
    this.paymentDate,
    this.notes,
  });

  SubscriptionStatus get status {
    final now = DateTime.now();
    final daysUntilEnd = endDate.difference(now).inDays;
    if (endDate.isBefore(now)) {
      return SubscriptionStatus.expired;
    }
    if (daysUntilEnd <= 7) {
      return SubscriptionStatus.expiringSoon;
    }
    return SubscriptionStatus.active;
  }

  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isExpiringSoon => status == SubscriptionStatus.expiringSoon;
  bool get isActive => status == SubscriptionStatus.active;
  int get daysUntilExpiry => endDate.difference(DateTime.now()).inDays;

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as int?,
      athleteId: map['athlete_id'] as int,
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == map['type'] as String,
        orElse: () => SubscriptionType.custom,
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      price: (map['price'] as num).toDouble(),
      isPaid: (map['is_paid'] as int) == 1,
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'athlete_id': athleteId,
      'type': type.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'price': price,
      'is_paid': isPaid ? 1 : 0,
      'payment_date': paymentDate?.toIso8601String(),
      'notes': notes,
    };
  }

  Subscription copyWith({
    int? id,
    int? athleteId,
    SubscriptionType? type,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    bool? isPaid,
    DateTime? paymentDate,
    String? notes,
  }) {
    return Subscription(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, athleteId: $athleteId, type: ${type.name}, '
        'endDate: $endDate, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
