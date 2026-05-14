import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GamificationService {
  final _storage = const FlutterSecureStorage();

  // Clés de stockage
  static const String _keyPoints = 'parent_gamification_points';
  static const String _keyBadges = 'parent_gamification_badges';

  static const int pointsPerConstante = 10;

  /// Récupère le total des points du parent
  Future<int> getPoints() async {
    if (kIsWeb) return 0;
    try {
      final pointsStr = await _storage.read(key: _keyPoints);
      return int.tryParse(pointsStr ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Liste des badges débloqués
  Future<List<String>> getUnlockedBadges() async {
    if (kIsWeb) return [];
    try {
      final badgesStr = await _storage.read(key: _keyBadges);
      if (badgesStr == null || badgesStr.isEmpty) return [];
      return badgesStr.split(',');
    } catch (e) {
      return [];
    }
  }

  /// Incrémente les points et vérifie les badges
  /// Renvoie le(s) nom(s) du/des nouveau(x) badge(s) débloqué(s) s'il y en a
  Future<List<String>> addPointsForConstante() async {
    if (kIsWeb) return [];
    try {
      final currentPoints = await getPoints();
      final newPoints = currentPoints + pointsPerConstante;
      
      await _storage.write(key: _keyPoints, value: newPoints.toString());
      return await _checkAndUnlockBadges(newPoints);
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _checkAndUnlockBadges(int points) async {
    if (kIsWeb) return [];
    try {
      final badges = await getUnlockedBadges();
    final newlyUnlocked = <String>[];
    bool updated = false;

    // Logique de badges (Gamification)
    if (points >= 50 && !badges.contains('Soignant Débutant')) {
      badges.add('Soignant Débutant');
      newlyUnlocked.add('Soignant Débutant');
      updated = true;
    }
    if (points >= 150 && !badges.contains('Protecteur Assidu')) {
      badges.add('Protecteur Assidu');
      newlyUnlocked.add('Protecteur Assidu');
      updated = true;
    }
    if (points >= 300 && !badges.contains('Héros de la Santé')) {
      badges.add('Héros de la Santé');
      newlyUnlocked.add('Héros de la Santé');
      updated = true;
    }
    if (points >= 500 && !badges.contains('Maître PCIME')) {
      badges.add('Maître PCIME');
      newlyUnlocked.add('Maître PCIME');
      updated = true;
    }

    if (updated) {
      await _storage.write(key: _keyBadges, value: badges.join(','));
    }

    return newlyUnlocked;
    } catch (e) {
      return [];
    }
  }
}
