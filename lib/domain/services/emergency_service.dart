import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/ambulance_model.dart';
import '../../data/models/hopital_model.dart';
import '../../data/models/pharmacie_model.dart';

class EmergencyService {
  static const String _jsonPath = 'assets/data/emergencies.json';

  List<AmbulanceModel> _ambulances = [];
  List<HopitalModel> _hopitaux = [];
  List<PharmacieModel> _pharmacies = [];

  bool _isDataLoaded = false;

  /// Loads the emergency data from the local JSON asset.
  Future<void> loadEmergencyData() async {
    if (_isDataLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString(_jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      if (jsonData.containsKey('ambulances')) {
        _ambulances = (jsonData['ambulances'] as List)
            .map((item) => AmbulanceModel.fromJson(item))
            .toList();
      }

      if (jsonData.containsKey('hopitaux_et_cliniques')) {
        _hopitaux = (jsonData['hopitaux_et_cliniques'] as List)
            .map((item) => HopitalModel.fromJson(item))
            .toList();
      }

      if (jsonData.containsKey('pharmacies_reseau_et_rotation')) {
        _pharmacies = (jsonData['pharmacies_reseau_et_rotation'] as List)
            .map((item) => PharmacieModel.fromJson(item))
            .toList();
      }

      _isDataLoaded = true;
    } catch (e) {
      throw Exception('Erreur lors du chargement des données d\'urgence: $e');
    }
  }

  /// Récupère toutes les ambulances
  List<AmbulanceModel> getAllAmbulances() {
    return _ambulances;
  }

  /// Récupère tous les hôpitaux
  List<HopitalModel> getAllHopitaux() {
    return _hopitaux;
  }

  /// Récupère toutes les pharmacies
  List<PharmacieModel> getAllPharmacies() {
    return _pharmacies;
  }

  /// Filtre les pharmacies par commune/zone géographique (ex: Itaosy, Analakely).
  List<PharmacieModel> getPharmaciesByZone(String keyword) {
    if (keyword.isEmpty) return _pharmacies;
    final lowerKeyword = keyword.toLowerCase();
    
    return _pharmacies.where((pharmacie) {
      return pharmacie.commune.toLowerCase().contains(lowerKeyword) ||
             pharmacie.adresse.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  /// Filtre les hôpitaux par zone géographique.
  List<HopitalModel> getHopitauxByZone(String keyword) {
    if (keyword.isEmpty) return _hopitaux;
    final lowerKeyword = keyword.toLowerCase();
    
    return _hopitaux.where((hopital) {
      return hopital.adresse.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  /// Filtre les ambulances par zone géographique.
  List<AmbulanceModel> getAmbulancesByZone(String keyword) {
    if (keyword.isEmpty) return _ambulances;
    final lowerKeyword = keyword.toLowerCase();
    
    return _ambulances.where((ambulance) {
      return ambulance.adresse.toLowerCase().contains(lowerKeyword);
    }).toList();
  }

  /// Recherche globale inter-catégories par mot clé.
  Map<String, dynamic> searchGlobal(String keyword) {
    return {
      'ambulances': getAmbulancesByZone(keyword),
      'hopitaux': getHopitauxByZone(keyword),
      'pharmacies': getPharmaciesByZone(keyword),
    };
  }

  /// Filtre les hôpitaux qui ont des spécialités pédiatriques, maternité, ou nourrissons.
  List<HopitalModel> getHopitauxPediatriques() {
    return _hopitaux.where((hopital) {
      if (hopital.note == null) return false;
      final lowerNote = hopital.note!.toLowerCase();
      return lowerNote.contains('pédiat') || 
             lowerNote.contains('enfant') || 
             lowerNote.contains('mère') || 
             lowerNote.contains('maternité') ||
             lowerNote.contains('néonat');
    }).toList();
  }
}
