class Athlete {
  final int? id;
  final String name;
  final String? firstName;
  final String phone;
  final String? email;
  final String? photoPath;
  final DateTime startDate;
  final DateTime? birthDate;
  final String? notes;
  final bool isActive;
  final String gender; // 'male' or 'female'

  const Athlete({
    this.id,
    required this.name,
    this.firstName,
    required this.phone,
    this.email,
    this.photoPath,
    required this.startDate,
    this.birthDate,
    this.notes,
    this.isActive = true,
    this.gender = 'male',
  });

  factory Athlete.fromMap(Map<String, dynamic> map) {
    return Athlete(
      id: map['id'] as int?,
      name: map['name'] as String,
      firstName: map['first_name'] as String?,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      photoPath: map['photo_path'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int) == 1,
      gender: map['gender'] as String? ?? 'male',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'first_name': firstName,
      'phone': phone,
      'email': email,
      'photo_path': photoPath,
      'start_date': startDate.toIso8601String(),
      'birth_date': birthDate?.toIso8601String(),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'gender': gender,
    };
  }

  Athlete copyWith({
    int? id,
    String? name,
    String? firstName,
    String? phone,
    String? email,
    String? photoPath,
    DateTime? startDate,
    DateTime? birthDate,
    String? notes,
    bool? isActive,
    String? gender,
  }) {
    return Athlete(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      startDate: startDate ?? this.startDate,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      gender: gender ?? this.gender,
    );
  }

  @override
  String toString() => 'Athlete(id: $id, name: $name, gender: $gender)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Athlete && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
