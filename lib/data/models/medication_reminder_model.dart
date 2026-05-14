class MedicationReminderModel {
  final int? id;
  final int enfantId;
  final String medName;
  final String dosage;
  final DateTime time;
  final bool isActive;

  MedicationReminderModel({
    this.id,
    required this.enfantId,
    required this.medName,
    required this.dosage,
    required this.time,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'medName': medName,
      'dosage': dosage,
      'time': time.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory MedicationReminderModel.fromMap(Map<String, dynamic> map) {
    return MedicationReminderModel(
      id: map['id'],
      enfantId: map['enfantId'],
      medName: map['medName'],
      dosage: map['dosage'],
      time: DateTime.parse(map['time']),
      isActive: map['isActive'] == 1,
    );
  }

  MedicationReminderModel copyWith({
    int? id,
    int? enfantId,
    String? medName,
    String? dosage,
    DateTime? time,
    bool? isActive,
  }) {
    return MedicationReminderModel(
      id: id ?? this.id,
      enfantId: enfantId ?? this.enfantId,
      medName: medName ?? this.medName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
    );
  }
}
