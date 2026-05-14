class AmbulanceModel {
  final String nom;
  final String adresse;
  final List<String> contacts;

  AmbulanceModel({
    required this.nom,
    required this.adresse,
    required this.contacts,
  });

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      contacts: List<String>.from(json['contacts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'adresse': adresse,
      'contacts': contacts,
    };
  }
}
