class ConstanteModel {
  final int? id;
  final int enfantId;
  final DateTime date;
  final double? poids;
  final double? taille;
  final double? temperature;
  final double? perimetreBrachial;

  ConstanteModel({
    this.id,
    required this.enfantId,
    required this.date,
    this.poids,
    this.taille,
    this.temperature,
    this.perimetreBrachial,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'date': date.toIso8601String(),
      'poids': poids,
      'taille': taille,
      'temperature': temperature,
      'perimetre_brachial': perimetreBrachial,
    };
  }

  factory ConstanteModel.fromMap(Map<String, dynamic> map) {
    return ConstanteModel(
      id: map['id'],
      enfantId: map['enfantId'],
      date: DateTime.parse(map['date']),
      poids: map['poids'],
      taille: map['taille'],
      temperature: map['temperature'],
      perimetreBrachial: map['perimetre_brachial'],
    );
  }
}
