import '../../data/models/vaccine_model.dart';
import '../../data/models/child_model.dart';
import '../../data/database/database_helper.dart';
import 'notification_service.dart';
import 'gamification_service.dart';

enum VaccineStatus {
  completed,
  upcoming,
  late,
}

class VaccinationScheduleItem {
  final String key;
  final String name;
  final int offsetDays;
  final bool isForGirlsOnly;

  VaccinationScheduleItem({
    required this.key,
    required this.name,
    required this.offsetDays,
    this.isForGirlsOnly = false,
  });
}

class VaccinationService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Catalogue complet du PEV Madagascar (0-9 ans)
  static final List<VaccinationScheduleItem> standardSchedule = [
    // Naissance (0 jours)
    VaccinationScheduleItem(key: 'bcg', name: 'BCG (Tuberculose)', offsetDays: 0),
    VaccinationScheduleItem(key: 'vpo_0', name: 'VPO 0 (Polio Oral)', offsetDays: 0),

    // 6 semaines (42 jours)
    VaccinationScheduleItem(key: 'penta_1', name: 'Pentavalent 1 (DTC-HepB-Hib 1)', offsetDays: 42),
    VaccinationScheduleItem(key: 'vpo_1', name: 'VPO 1 (Polio Oral)', offsetDays: 42),
    VaccinationScheduleItem(key: 'pcv13_1', name: 'PCV 13 (1) (Pneumocoque)', offsetDays: 42),
    VaccinationScheduleItem(key: 'rotarix_1', name: 'Rotarix 1 (Rotavirus)', offsetDays: 42),

    // 10 semaines (70 jours)
    VaccinationScheduleItem(key: 'penta_2', name: 'Pentavalent 2 (DTC-HepB-Hib 2)', offsetDays: 70),
    VaccinationScheduleItem(key: 'vpo_2', name: 'VPO 2 (Polio Oral)', offsetDays: 70),
    VaccinationScheduleItem(key: 'pcv13_2', name: 'PCV 13 (2) (Pneumocoque)', offsetDays: 70),
    VaccinationScheduleItem(key: 'rotarix_2', name: 'Rotarix 2 (Rotavirus)', offsetDays: 70),

    // 14 semaines (98 jours)
    VaccinationScheduleItem(key: 'penta_3', name: 'Pentavalent 3 (DTC-HepB-Hib 3)', offsetDays: 98),
    VaccinationScheduleItem(key: 'vpo_3', name: 'VPO 3 (Polio Oral)', offsetDays: 98),
    VaccinationScheduleItem(key: 'pcv13_3', name: 'PCV 13 (3) (Pneumocoque)', offsetDays: 98),
    VaccinationScheduleItem(key: 'vpi_1', name: 'VPI 1 (Polio Injectable)', offsetDays: 98),

    // 6 mois (~182 jours)
    VaccinationScheduleItem(key: 'vita_1', name: 'Vitamine A (Dose 1) - 100 000 UI', offsetDays: 182),

    // 9 mois (~273 jours)
    VaccinationScheduleItem(key: 'var_1', name: 'VAR 1 ou RR 1 (Rougeole/Rubéole 1)', offsetDays: 273),
    VaccinationScheduleItem(key: 'vpi_2', name: 'VPI 2 (Polio Injectable Rappel)', offsetDays: 273),

    // 12 mois (~365 jours)
    VaccinationScheduleItem(key: 'vita_2', name: 'Vitamine A (Dose 2) - 200 000 UI', offsetDays: 365),
    VaccinationScheduleItem(key: 'alben_1', name: 'Albendazole (Dose 1)', offsetDays: 365),

    // 15 mois (~456 jours)
    VaccinationScheduleItem(key: 'var_2', name: 'VAR 2 ou RR 2 (Rougeole/Rubéole 2)', offsetDays: 456),

    // 18 mois (~547 jours)
    VaccinationScheduleItem(key: 'vita_3', name: 'Vitamine A (Dose 3) - 200 000 UI', offsetDays: 547),
    VaccinationScheduleItem(key: 'alben_2', name: 'Albendazole (Dose 2)', offsetDays: 547),

    // Suivis Vit A & Albendazole tous les 6 mois de 24 à 60 mois
    VaccinationScheduleItem(key: 'vita_4', name: 'Vitamine A (Dose 4)', offsetDays: 730), // 24 mois
    VaccinationScheduleItem(key: 'alben_3', name: 'Albendazole (Dose 3)', offsetDays: 730),
    VaccinationScheduleItem(key: 'vita_5', name: 'Vitamine A (Dose 5)', offsetDays: 912), // 30 mois
    VaccinationScheduleItem(key: 'alben_4', name: 'Albendazole (Dose 4)', offsetDays: 912),
    VaccinationScheduleItem(key: 'vita_6', name: 'Vitamine A (Dose 6)', offsetDays: 1095), // 36 mois
    VaccinationScheduleItem(key: 'alben_5', name: 'Albendazole (Dose 5)', offsetDays: 1095),
    VaccinationScheduleItem(key: 'vita_7', name: 'Vitamine A (Dose 7)', offsetDays: 1277), // 42 mois
    VaccinationScheduleItem(key: 'alben_6', name: 'Albendazole (Dose 6)', offsetDays: 1277),
    VaccinationScheduleItem(key: 'vita_8', name: 'Vitamine A (Dose 8)', offsetDays: 1460), // 48 mois
    VaccinationScheduleItem(key: 'alben_7', name: 'Albendazole (Dose 7)', offsetDays: 1460),
    VaccinationScheduleItem(key: 'vita_9', name: 'Vitamine A (Dose 9)', offsetDays: 1642), // 54 mois
    VaccinationScheduleItem(key: 'alben_8', name: 'Albendazole (Dose 8)', offsetDays: 1642),
    VaccinationScheduleItem(key: 'vita_10', name: 'Vitamine A (Dose 10)', offsetDays: 1825), // 60 mois
    VaccinationScheduleItem(key: 'alben_9', name: 'Albendazole (Dose 9)', offsetDays: 1825),

    // 9 ans (pour les filles uniquement) - approx 3285 jours
    VaccinationScheduleItem(key: 'hpv_1', name: 'HPV (Dose 1) - Papillomavirus', offsetDays: 3285, isForGirlsOnly: true),
    VaccinationScheduleItem(key: 'hpv_2', name: 'HPV (Dose 2) - Papillomavirus', offsetDays: 3468, isForGirlsOnly: true), // +6 mois
  ];

  /// Initialise la grille vaccinale pour un enfant nouvellement créé ou s'il manque des entrées.
  Future<void> initializeVaccinesForChild(ChildModel child) async {
    if (child.id == null) return;

    final existingVaccines = await _dbHelper.getVaccinesForChild(child.id!);
    final existingKeys = existingVaccines.map((v) => v.vaccineKey).toSet();

    // Import temporaire pour ne pas briser la logique si importé globalement
    // La déclaration sera vérifiée. On suppose que NotificationService est utilisé.
    // Pour éviter boucle importe ou erreurs, instanciez-le localement ou ajoutez l'import en haut.
    
    for (var item in standardSchedule) {
      if (item.isForGirlsOnly && child.gender.toLowerCase() != 'fille' && child.gender.toLowerCase() != 'female' && child.gender.toLowerCase() != 'f') {
        continue; // Ignorer le HPV pour les garçons
      }

      if (!existingKeys.contains(item.key)) {
        final datePlanned = child.birthDate.add(Duration(days: item.offsetDays));
        final newVaccine = VaccineModel(
          enfantId: child.id!,
          vaccineKey: item.key,
          vaccineName: item.name,
          datePlanned: datePlanned,
          isCompleted: false,
        );
        final id = await _dbHelper.addVaccine(newVaccine);
        
        // Schedule notification for this new vaccine
        final savedVaccine = VaccineModel(
          id: id,
          enfantId: newVaccine.enfantId,
          vaccineKey: newVaccine.vaccineKey,
          vaccineName: newVaccine.vaccineName,
          datePlanned: newVaccine.datePlanned,
          isCompleted: newVaccine.isCompleted,
        );
        _scheduleNotificationForVaccine(savedVaccine, child);
      }
    }
  }

  void _scheduleNotificationForVaccine(VaccineModel savedVaccine, ChildModel child) {
    NotificationService().scheduleVaccinationReminder(savedVaccine, child);
  }

  Future<void> scheduleAllUpcomingVaccinations() async {
    final children = await _dbHelper.readAllChildren();
    for (var child in children) {
      if (child.id != null) {
        final vaccines = await _dbHelper.getVaccinesForChild(child.id!);
        for (var vaccine in vaccines) {
          if (!vaccine.isCompleted) {
            _scheduleNotificationForVaccine(vaccine, child);
          }
        }
      }
    }
  }

  /// Récupère et met à jour dynamiquement la liste de vaccins de l'enfant
  Future<List<VaccineModel>> getVaccines(ChildModel child) async {
    if (child.id == null) return [];
    await initializeVaccinesForChild(child);
    return await _dbHelper.getVaccinesForChild(child.id!);
  }

  /// Détermine le statut en temps réel d'un vaccin
  VaccineStatus getStatus(VaccineModel vaccine) {
    if (vaccine.isCompleted) {
      return VaccineStatus.completed;
    }

    final now = DateTime.now();
    // En retard si la date cible est dépassée de plus de 14 jours et non coché
    final lateThreshold = vaccine.datePlanned.add(const Duration(days: 14));

    if (now.isAfter(lateThreshold)) {
      return VaccineStatus.late;
    } else {
      return VaccineStatus.upcoming; // À faire (ou à venir si la date n'est pas encore arrivée, on englobe tout dans 'upcoming' et on l'affichera en orange/gris selon)
    }
  }

  /// Marque un vaccin comme effectué (ou annule)
  Future<void> markVaccineAdministered(VaccineModel vaccine, DateTime administrationDate) async {
    final updatedVaccine = VaccineModel(
      id: vaccine.id,
      enfantId: vaccine.enfantId,
      vaccineKey: vaccine.vaccineKey,
      vaccineName: vaccine.vaccineName,
      datePlanned: vaccine.datePlanned,
      dateAdministered: administrationDate,
      isCompleted: true,
    );
    await _dbHelper.updateVaccine(updatedVaccine);
    
    // Annule la notification vu que c'est fait
    if (vaccine.id != null) {
      NotificationService().cancelReminder(vaccine.id! + 100000);
    }

    GamificationService().addPointsForAction('vaccination');
  }

  /// Annule une vaccination cochée par erreur
  Future<void> unmarkVaccine(VaccineModel vaccine) async {
    final updatedVaccine = VaccineModel(
      id: vaccine.id,
      enfantId: vaccine.enfantId,
      vaccineKey: vaccine.vaccineKey,
      vaccineName: vaccine.vaccineName,
      datePlanned: vaccine.datePlanned,
      dateAdministered: null,
      isCompleted: false,
    );
    await _dbHelper.updateVaccine(updatedVaccine);
    
    // Reprogramme la notification
    final child = await _dbHelper.getChild(vaccine.enfantId);
    if (child != null) {
      _scheduleNotificationForVaccine(updatedVaccine, child);
    }
  }
}
