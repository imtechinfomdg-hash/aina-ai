class HopitalModel {
  final String nom;
  final String adresse;
  final List<String> contacts;
  final String? note;

  HopitalModel({
    required this.nom,
    required this.adresse,
    required this.contacts,
    this.note,
  });

  factory HopitalModel.fromJson(Map<String, dynamic> json) {
    return HopitalModel(
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      contacts: List<String>.from(json['contacts'] ?? []),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'adresse': adresse,
      'contacts': contacts,
      'note': note,
    };
  }
}
