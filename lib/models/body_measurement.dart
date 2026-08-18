class BodyMeasurement {
  final int? id;
  final int athleteId;
  final DateTime date;
  final double? weight;
  final double? height;
  final double? chest;
  final double? abdomen;
  final double? thigh;
  final double? arm;
  final String? notes;

  const BodyMeasurement({
    this.id,
    required this.athleteId,
    required this.date,
    this.weight,
    this.height,
    this.chest,
    this.abdomen,
    this.thigh,
    this.arm,
    this.notes,
  });

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return BodyMeasurement(
      id: map['id'] as int?,
      athleteId: map['athlete_id'] as int,
      date: DateTime.parse(map['date'] as String),
      weight: toDouble(map['weight']),
      height: toDouble(map['height']),
      chest: toDouble(map['chest']),
      abdomen: toDouble(map['abdomen']),
      thigh: toDouble(map['thigh']),
      arm: toDouble(map['arm']),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'athlete_id': athleteId,
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'chest': chest,
      'abdomen': abdomen,
      'thigh': thigh,
      'arm': arm,
      'notes': notes,
    };
  }

  BodyMeasurement copyWith({
    int? id,
    int? athleteId,
    DateTime? date,
    double? weight,
    double? height,
    double? chest,
    double? abdomen,
    double? thigh,
    double? arm,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chest: chest ?? this.chest,
      abdomen: abdomen ?? this.abdomen,
      thigh: thigh ?? this.thigh,
      arm: arm ?? this.arm,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'BodyMeasurement(id: $id, athleteId: $athleteId, date: $date)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BodyMeasurement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}