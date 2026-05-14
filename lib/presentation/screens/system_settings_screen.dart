import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _isLoading = true;
  bool _isLlamaFilePresent = false;
  bool _isTtsReady = false;

  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _runSystemChecks();
  }

  Future<void> _runSystemChecks() async {
    setState(() => _isLoading = true);
    
    await _checkLlamaModel();
    await _checkTtsSupport();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLlamaModel() async {
    if (kIsWeb) {
      _isLlamaFilePresent = false;
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/llama-3.2-1b-instruct-q4_k_m.gguf');
      final exists = await modelFile.exists();
      _isLlamaFilePresent = exists;
    } catch (e) {
      _isLlamaFilePresent = false;
    }
  }

  Future<void> _checkTtsSupport() async {
    try {
      final tts = FlutterTts();
      final languages = await tts.getLanguages;
      if (languages is List) {
        final List<String> langStrings = languages.map((e) => e.toString().toLowerCase()).toList();
        // Vérifie si un pack de langue pour français ou anglais est présent pour le fallback de prononciation
        _isTtsReady = langStrings.any((lang) => lang.contains('fr') || lang.contains('en'));
      } else {
        _isTtsReady = true; // Fallback optimiste
      }
    } catch (e) {
      _isTtsReady = false;
    }
  }

  Future<void> _performGlobalPurge() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action indisponible sur le Web.")));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Droit à l'oubli", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "ATTENTION : Cette action va supprimer instantanément, de façon destructive et irréversible, "
          "toutes les bases de données locales, de tous vos enfants, les paramètres de sécurité (clés ECC/AES) et l'historique de l'IA.\n\n"
          "Êtes-vous absolument sûr de vouloir tout effacer ?",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Purger Définitivement", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (confirmed == true) {
      try {
        // 1. Purge Secure Storage (Clés cryptographiques, préférences)
        const secureStorage = FlutterSecureStorage();
        await secureStorage.deleteAll();

        // 2. Suppression destructrice de la base de données SQLite
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'aina_local.db');
        await deleteDatabase(path);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: creamBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Purge effectuée avec succès", style: TextStyle(color: Colors.red)),
              content: const Text("L'application a été réinitialisée. Toutes les données ont été détruites. \nUne reconnexion est nécessaire."),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // On retourne à l'écran racine (qui devrait relancer l'authentification/init si rouvert)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la purge : $e")),
          );
        }
      }
    }
  }

  Widget _buildStatusTile({required String title, required String subtitle, required bool isHealthy}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHealthy ? primaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? primaryGreen : Colors.red,
            size: 32,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle, style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Paramètres Système", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text("Diagnostic Matériel", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              
              // Voyant fichier GGUF
              _buildStatusTile(
                title: "Moteur Llama (On-Device)",
                subtitle: _isLlamaFilePresent 
                  ? "Modèle GGUF disponible localement.\nPrêt pour l'inférence hors-ligne." 
                  : "Fichier llama-3.2-1b-instruct-q4_k_m.gguf introuvable.\nLigne de commande d'extraction nécessaire.",
                isHealthy: _isLlamaFilePresent,
              ),

              // Voyant moteur TTS
              _buildStatusTile(
                title: "Moteur Vocal (TTS)",
                subtitle: _isTtsReady 
                  ? "Packs linguistiques liés avec succès.\nLa synthèse vocale est active." 
                  : "Aucun pack linguistique système détecté.\nFonction 'Hihaino' indisponible.",
                isHealthy: _isTtsReady,
              ),

              const SizedBox(height: 40),
              
              const Row(
                children: [
                  Icon(Icons.shield, color: primaryGreen, size: 28),
                  SizedBox(width: 12),
                  Text("Confidentialité", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen)),
                ],
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                          SizedBox(width: 12),
                          Text(
                            "Droit à l'oubli", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Cette action de maintenance purge toutes les données sur ce téléphone (Bases SQLite, Historique IA, Clés de chiffrement ECC). Elle est irréversible.",
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text("Effacer toutes les données", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: _performGlobalPurge,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
    );
  }
}
