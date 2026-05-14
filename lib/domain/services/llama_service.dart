import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'knowledge_base_service.dart';

// Import fictif à décommenter lors de la compilation réelle avec llamadart
// import 'package:llamadart/llamadart.dart';

/// Service gérant l'exécution de l'inférence locale (On-Device) via llama.cpp
class LlamaService {
  static const String _modelAssetName = 'assets/models/llama-3.2-1b-instruct-q4_k_m.gguf';
  String? _modelPath;
  bool _isInitialized = false;
  
  final KnowledgeBaseService _kbService;
  
  // Instance du modèle LLM
  // Llama? _llama;

  LlamaService(this._kbService);

  /// Charge le fichier GGUF en mémoire et initialise l'instance Llama
  Future<void> initializeModel() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/llama-3.2-1b-instruct-q4_k_m.gguf');

      // Extraction du modèle compressé GGUF depuis les assets vers le stockage interne
      if (!await modelFile.exists()) {
        print("Extraction du modèle Llama GGUF en cours...");
        final byteData = await rootBundle.load(_modelAssetName);
        await modelFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      }

      _modelPath = modelFile.path;

      // Instanciation de llamadart avec l'accès direct au fichier physique
      // _llama = Llama(modelPath: _modelPath!);
      
      _isInitialized = true;
      print("Modèle Llama chargé en mémoire avec succès : $_modelPath");
    } catch (e) {
      throw Exception("Erreur lors de l'initialisation du modèle Llama : $e");
    }
  }

  /// Génère une réponse sécurisée basée sur le triage OMS local en fonction de la langue
  Future<String> generateTriageResponse(String userQuery, String languageCode) async {
    if (!_isInitialized) {
      throw Exception("Le modèle Llama n'est pas prêt. Veuillez l'initialiser d'abord.");
    }

    // 1. Récupération du contexte clinique pertinent
    final String contextBlock = _kbService.getRelevantContext(userQuery);

    // 2. Création dynamique du System Prompt selon la locale
    String systemPrompt = "";
    
    if (languageCode == 'mg' || languageCode == 'mg_MG') {
      systemPrompt = """Ianao dia 'Aina', mpanampy ara-pahasalamana ho an'ny zaza eto Madagasikara. 
Mamalia amim-panajana sy fahalalam-pomba tsara (fomba kabary na teny malagasy madio). 
NY VALINTENINAO DIA TSY MAINTSY MIANKINA TANTERAKA AMIN'ITY LOHARANOM-PAHASALAMANA MANARAKA ITY IHANY (avy amin'ny OMS PCIME). 
Aza mamorona na manampy fanafody na aretina ivelan'io loharano io. 
Raha misy tranga mampiahiahy na atahorana ho faty ny zaza, manoro hevitra ny ray aman-dreny mba hanatona tobim-pahasalamana (CSB) na hopitaly faran'izay haingana.

LOHARANO / CONTEXTE :
$contextBlock""";
    } else if (languageCode == 'en' || languageCode == 'en_US') {
      systemPrompt = """You are 'Aina', an infant health assistant for Madagascar. 
ANSWER EXCLUSIVELY based on the following CLINICAL CONTEXT (from WHO IMCI guidelines). 
Never invent medical information, diseases, or treatments. Do not hallucinate.
If there is any sign of severe danger or emergency, strictly advise the parent to go to the nearest health center (CSB) or hospital immediately.

CLINICAL CONTEXT:
$contextBlock""";
    } else {
      // Par défaut : Français
      systemPrompt = """Tu es 'Aina', une assistante de santé infantile pour Madagascar. 
RÉPONDS EXCLUSIVEMENT en te basant sur le CONTEXTE CLINIQUE suivant (issu des protocoles de l'OMS PCIME). 
N'invente jamais d'informations médicales ni de maladies qui ne sont pas dans ce contexte. 
En cas de signe de danger de mort ou de gravité, recommande catégoriquement aux parents de se rendre au centre de santé (CSB) ou à l'hôpital immédiatement.

CONTEXTE CLINIQUE :
$contextBlock""";
    }

    // 3. Modèle de formatage strict Llama-3-Instruct
    final String prompt = '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>
$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>
$userQuery<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';

    // 4. Appel d'inférence (On-Device via FFI)
    print("Exécution de l'inférence locale Llama-3.2-1B-Instruct...");
    
    // final response = await _llama?.prompt(prompt, temperature: 0.1, maxTokens: 256);
    // return response ?? "Erreur de génération interne.";

    // Renvoi simulatif sans le moteur hardware acté
    return "[SIMULATION LOCALE] Llama a reçu et traité la requête en '$languageCode' avec le contexte médical exclusif. La génération respecte le protocole PCIME.";
  }

  /// Vérifie les incompatibilités majeures entre un nouveau médicament et les traitements en cours
  Future<String?> checkDrugInteraction(List<dynamic> currentMeds, dynamic newMed) async {
    // Convert to simple names
    final currentNames = currentMeds.map((m) => m.medName).join(', ');
    final newName = newMed.medName;

    if (currentNames.isEmpty) return null;

    final String systemPrompt = """Tu es 'Aina', un assistant pédiatrique expert. 
Analyse SEULEMENT la compatibilité entre ce nouveau médicament: "$newName" et la liste des médicaments actuels de l'enfant: "$currentNames".
S'il y a un danger grave d'interaction connu pour un nourrisson, réponds par le motif de danger en UNE phrase.
S'il n'y a pas d'interaction majeure évidente, réponds EXACTEMENT par le mot "SAFE".
Ne fais pas de consultation complète.""";

    final String prompt = '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>
$systemPrompt<|eot_id|><|start_header_id|>user<|end_header_id|>
Y a-t-il une interaction dangereuse ?<|eot_id|><|start_header_id|>assistant<|end_header_id|>''';

    // Simulation de l'inférence :
    // final response = await _llama?.prompt(prompt, temperature: 0.1, maxTokens: 100);
    // if (response?.trim().toUpperCase() == "SAFE") return null;
    // return response;
    
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulation: Ibuprofene + Aspirine = Danger
    if (newName.toLowerCase().contains("ibuprofène") && currentNames.toLowerCase().contains("aspirine") ||
        newName.toLowerCase().contains("aspirine") && currentNames.toLowerCase().contains("ibuprofène")) {
      return "Attention: Risque élevé de saignement ou d'interaction toxique avec la combinaison de ces anti-inflammatoires.";
    }

    return null;
  }
}
