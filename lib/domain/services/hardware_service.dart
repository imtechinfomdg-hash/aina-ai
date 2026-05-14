import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:device_info_plus/device_info_plus.dart';

class HardwareService {
  static final HardwareService _instance = HardwareService._internal();
  factory HardwareService() => _instance;
  HardwareService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Évalue la mémoire RAM totale disponible physiquement sur l'appareil (en MegaOctets)
  Future<int> getTotalRAMInMB() async {
    if (kIsWeb) return 4096;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Lecture directe de /proc/meminfo (Méthode robuste sous Android/Linux)
        final meminfo = await File('/proc/meminfo').readAsString();
        final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(meminfo);
        
        if (match != null) {
          final memTotalKB = int.parse(match.group(1)!);
          return memTotalKB ~/ 1024; // Conversion kB -> MB
        }
      } catch (e) {
        print("Erreur de lecture de la RAM dans /proc/meminfo : \$e");
      }
    }
    
    // Valeur de secours si impossible à déterminer (on assume 4Go par défaut)
    return 4096;
  }

  /// Retourne un indicateur pour savoir si le système nécessite le petit modèle LLM (1B)
  Future<bool> shouldUseLightweightModel() async {
    final ramMB = await getTotalRAMInMB();
    print("Évaluation RAM système : \${ramMB} Mo");
    
    // Si la RAM détectée est inférieure à 3 Go (3000 Mo)
    if (ramMB < 3000) {
      print("Mode 'Low-Res' activé : Forçage de l'instance Llama-1B pour préserver la fluidité.");
      return true;
    }
    
    return false;
  }
}
