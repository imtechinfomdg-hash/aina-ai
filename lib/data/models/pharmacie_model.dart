class PharmacieModel {
  final String nom;
  final String adresse;
  final List<String> contacts;
  final String commune;

  PharmacieModel({
    required this.nom,
    required this.adresse,
    required this.contacts,
    required this.commune,
  });

  factory PharmacieModel.fromJson(Map<String, dynamic> json) {
    return PharmacieModel(
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      contacts: List<String>.from(json['contacts'] ?? []),
      commune: json['commune'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'adresse': adresse,
      'contacts': contacts,
      'commune': commune,
    };
  }
}
