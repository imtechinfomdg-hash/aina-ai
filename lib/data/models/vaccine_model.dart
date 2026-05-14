class VaccineModel {
  final int? id;
  final int enfantId;
  final String vaccineKey; // Identifiant interne unique
  final String vaccineName; // Nom affiché
  final DateTime datePlanned;
  final DateTime? dateAdministered;
  final bool isCompleted;

  VaccineModel({
    this.id,
    required this.enfantId,
    required this.vaccineKey,
    required this.vaccineName,
    required this.datePlanned,
    this.dateAdministered,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'vaccineKey': vaccineKey,
      'vaccineName': vaccineName,
      'datePlanned': datePlanned.toIso8601String(),
      'dateAdministered': dateAdministered?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory VaccineModel.fromMap(Map<String, dynamic> map) {
    return VaccineModel(
      id: map['id'],
      enfantId: map['enfantId'],
      vaccineKey: map['vaccineKey'],
      vaccineName: map['vaccineName'],
      datePlanned: DateTime.parse(map['datePlanned']),
      dateAdministered: map['dateAdministered'] != null ? DateTime.parse(map['dateAdministered']) : null,
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
