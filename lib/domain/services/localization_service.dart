import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  final _storage = const FlutterSecureStorage();
  String _currentLanguage = 'MG'; // Default to Malagasy
  
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    String? lang = await _storage.read(key: 'app_language');
    if (lang != null && ['MG', 'FR', 'EN'].contains(lang)) {
      _currentLanguage = lang;
    } else {
      _currentLanguage = 'MG';
      await _storage.write(key: 'app_language', value: _currentLanguage);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (['MG', 'FR', 'EN'].contains(lang)) {
      _currentLanguage = lang;
      await _storage.write(key: 'app_language', value: _currentLanguage);
      notifyListeners();
    }
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? _translations['MG']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'MG': {
      'hello_mom': 'Salama, Nenibe 👶💛',
      'baby_doing_great': 'Manao ahoana ny zaza androany',
      'baby_status': 'Sata-jaza',
      'happy_active': 'Miramirana & Mavitrika 😊',
      'last_fed': 'Nisakafo farany: 1 ora',
      'add_activity': 'Hampiditra',
      'feed': 'Sakafo',
      'sleep': 'Torimaso',
      'diaper': 'Lamba',
      'growth': 'Fitombo',
      'routine': 'Fanao',
      'add_log': 'Karakara maika',
      'baby_assistant': 'Mpanampy',
      'morning_nap': 'Torimaso maraina 😴',
      'slept_for': 'Natory 30 minitra',
      'start_tracking': 'Hanomboka ny fanaraha-maso',
      'care_for_baby': 'Karakarao ny zaza\nFanaraha-maso tsara',
      'onboarding_subtitle': 'Ny fampahalalana andavanandro amin\'ny toerana iray. Arahi-maso mora foana ny fitombon\'ny zaza.',
      'agree_to': 'Manaiky ny ',
      'terms': 'Fepetra eto amin\'ny Projet Aina aho',
      'and_consent': ' sy ny fikirakirana ny angona ara-pahasalamana.',
      'get_started': 'Hanomboka',
      'activity_tracker': 'Fanaraha-maso ny atao',
      'day': 'Andro',
      'week': 'Herin.',
      'month': 'Volana',
      'year': 'Taona',
      'daily_activity_overview': 'Topy mason\'ny asan\'andro',
      'today': 'Anio',
      'total_activities': 'Hetsika rehetra',
      'logs_today': 'Voarakitra anio',
      'todays_overview': 'Topy mason\'ny androany',
      'hydration': 'Rano',
      'playtime': 'Kilalao',
      'bath': 'Fandroana',
    },
    'EN': {
      'hello_mom': 'Hello, Mom 👶💛',
      'baby_doing_great': 'Baby is doing great today',
      'baby_status': 'Baby Status',
      'happy_active': 'Happy & Active 😊',
      'last_fed': 'Last fed 1 hour ago',
      'add_activity': 'Add Activity',
      'feed': 'Feed',
      'sleep': 'Sleep',
      'diaper': 'Diaper',
      'growth': 'Growth',
      'routine': 'Routine',
      'add_log': 'First Aid',
      'baby_assistant': 'Baby Assistant',
      'morning_nap': 'Morning Nap 😴',
      'slept_for': 'Slept for 30 minutes',
      'start_tracking': 'Start Tracking',
      'care_for_baby': 'Care For Your Baby\nSmart Tracking',
      'onboarding_subtitle': 'Daily activities in one simple place. Monitor your\nbaby\'s growth and milestones with ease.',
      'agree_to': 'I agree to the ',
      'terms': 'Terms and Conditions',
      'and_consent': ' and consent to the processing of personal health data.',
      'get_started': 'Get Started',
      'activity_tracker': 'Activity Tracker',
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'daily_activity_overview': 'Daily Activity Overview',
      'today': 'Today',
      'total_activities': 'Total Activities',
      'logs_today': 'Logs Today',
      'todays_overview': "Today's Baby Care Overview",
      'hydration': 'Hydration',
      'playtime': 'Playtime',
      'bath': 'Bath',
    },
    'FR': {
      'hello_mom': 'Bonjour, Maman 👶💛',
      'baby_doing_great': 'Bébé va très bien aujourd\'hui',
      'baby_status': 'Statut Bébé',
      'happy_active': 'Heureux & Actif 😊',
      'last_fed': 'Dernier repas il y a 1h',
      'add_activity': 'Ajouter activité',
      'feed': 'Nourrir',
      'sleep': 'Dormir',
      'diaper': 'Couche',
      'growth': 'Croissance',
      'routine': 'Routine',
      'add_log': 'Premiers secours',
      'baby_assistant': 'Assistant Bébé',
      'morning_nap': 'Sieste matinale 😴',
      'slept_for': 'A dormi 30 minutes',
      'start_tracking': 'Commencer le suivi',
      'care_for_baby': 'Prenez soin de bébé\nSuivi intelligent',
      'onboarding_subtitle': 'Activités quotidiennes en un seul endroit. Suivez la\ncroissance et les étapes de bébé en toute simplicité.',
      'agree_to': 'J\'accepte les ',
      'terms': 'Conditions générales',
      'and_consent': ' et je consens au traitement de mes données de santé.',
      'get_started': 'Commencer',
      'activity_tracker': 'Suivi d\'activité',
      'day': 'Jour',
      'week': 'Sem.',
      'month': 'Mois',
      'year': 'Année',
      'daily_activity_overview': 'Aperçu quotidien',
      'today': 'Auj.',
      'total_activities': 'Total activités',
      'logs_today': 'Registres auj.',
      'todays_overview': 'Aperçu des soins',
      'hydration': 'Hydratation',
      'playtime': 'Jeux',
      'bath': 'Bain',
    }
  };
}
