import 'package:flutter/services.dart';

class KnowledgeBaseService {
  static const String _kbPath = 'assets/data/oms_pcime.txt';
  String _fullText = '';

  /// Charge le contenu de la base de connaissances médicale depuis les assets
  Future<void> loadKnowledgeBase() async {
    if (_fullText.isNotEmpty) return;
    try {
      _fullText = await rootBundle.loadString(_kbPath);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la base de données OMS PCIME : $e');
    }
  }

  /// Retourne le texte complet
  String getFullText() => _fullText;

  /// Nettoie la requête utilisateur : minuscules et suppression des ponctuations
  String _cleanQuery(String query) {
    return query
        .toLowerCase()
        // Remplace toute ponctuation par des espaces, en gardant les lettres et chiffres
        .replaceAll(RegExp(r'[^\w\sàâäéèêëîïôöùûüçñ-]'), ' ')
        // Réduit les espaces multiples à un seul espace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extrait la section pertinente en fonction des mots-clés de la requête de l'utilisateur.
  /// Mécanisme d'indexation trilingue (Malgache, Français, Anglais).
  String getRelevantContext(String userQuery) {
    if (_fullText.isEmpty) {
      return "Erreur : La base de données clinique n'est pas chargée.";
    }

    final String cleanQuery = _cleanQuery(userQuery);
    final List<String> queryWords = cleanQuery.split(' ');

    // Dictionnaire trilingue associant chaque module à ses mots-clés
    // [Français, Malagasy, English]
    final Map<String, List<String>> modulesKeywords = {
      'MODULE 1': [
        'danger', 'urgence', 'convulsion', 'convulsions', 'mandoa', 'vomir', 'vomit',
        'matory', 'léthargique', 'lethargic', 'inconscient', 'unconscious',
        'faty', 'tana', 'sotro', 'boire', 'drink'
      ],
      'MODULE 2': [
        'toux', 'kohaka', 'cough', 'respiration', 'sempotra', 'breathing',
        'tsempotra', 'tirage', 'pneumonie', 'pneumonia', 'tratra', 'poitrine', 
        'chest', 'rhume', 'sokoka', 'sento', 'stridor', 'souffle'
      ],
      'MODULE 3': [
        'diarrhée', 'manavy', 'fivalanana', 'diarrhea', 'déshydratation', 'dehydration',
        'ritra', 'rano', 'water', 'soif', 'thirsty', 'buveur', 'lavaka', 'enfoncé',
        'sro', 'zinc', 'dysenterie', 'dysentery', 'selle', 'sang', 'blood', 'ra'
      ],
      'MODULE 4': [
        'fièvre', 'feve', 'tazo', 'fever', 'hafana', 'mafana', 'chaud', 'hot',
        'paludisme', 'malaria', 'moka', 'moustache', 'mosquito', 'rougeole', 
        'korisa', 'ramboteza', 'measles', 'tana', 'skoka', 'hazandrano', 'tdr'
      ],
      'MODULE 5': [
        'malnutrition', 'anémie', 'anemia', 'sakafo', 'food', 'hatsatra', 'pâleur', 'pale',
        'mahia', 'émaciation', 'thin', 'poids', 'weight', 'taille', 'height', 'mivonto', 
        'œdème', 'edema', 'kwashiorkor', 'pb', 'brachial', 'muac'
      ],
    };

    // Comptage des occurrences pour chaque module
    final Map<String, int> matchScores = {};
    for (String moduleKey in modulesKeywords.keys) {
      matchScores[moduleKey] = 0;
      for (String keyword in modulesKeywords[moduleKey]!) {
        // Recherche de la racine du mot (ex: 'convulsion' matche 'convulsions')
        if (queryWords.any((word) => word.contains(keyword) || keyword.contains(word) && word.length > 3)) {
          matchScores[moduleKey] = matchScores[moduleKey]! + 1;
        }
      }
    }

    // Déterminer le module avec le score le plus élevé
    String bestModule = '';
    int maxScore = 0;
    matchScores.forEach((module, score) {
      if (score > maxScore) {
        maxScore = score;
        bestModule = module;
      }
    });

    final sections = _fullText.split('--------------------------------------------------------------------------------');
    
    // Si correspondance trouvée
    if (bestModule.isNotEmpty && maxScore > 0) {
      for (var section in sections) {
        if (section.trim().startsWith(bestModule)) {
          return "AINA APP - BASE DE DONNÉES CLINIQUE OFFICIELLE - PCIME / OMS HORS-LIGNE (0-5 ANS)\n\n"
                 "--------------------------------------------------------------------------------\n"
                 "\${section.trim()}\n"
                 "--------------------------------------------------------------------------------\n";
        }
      }
    }

    // Par défaut, alerter sur le Module 1 si aucune correspondance spécifique
    String defaultModule1 = "";
    for (var section in sections) {
      if (section.trim().startsWith('MODULE 1')) {
        defaultModule1 = section.trim();
        break;
      }
    }

    return "AINA APP - BASE DE DONNÉES CLINIQUE OFFICIELLE\n\n"
           "Aucun contexte médical spécifique identifié explicitement pour cette requête. "
           "PAR SÉCURITÉ, VEUILLEZ TOUJOURS VÉRIFIER LES SIGNES GÉNÉRAUX DE DANGER :\n\n"
           "--------------------------------------------------------------------------------\n"
           "\$defaultModule1\n"
           "--------------------------------------------------------------------------------\n";
  }
}
