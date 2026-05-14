import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricSecurityService {
  static final BiometricSecurityService _instance = BiometricSecurityService._internal();
  factory BiometricSecurityService() => _instance;
  BiometricSecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Demande l'empreinte digitale de l'utilisateur pour déverrouiller l'application
  Future<bool> authenticateUser() async {
    if (kIsWeb) return true;
    try {
      // Vérifier si le matériel biométrique est disponible
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // En mode dégradé (sans capteur), on autorise l'accès ou on demande un PIN (ici autorisé par défaut pour l'exemple)
        return true; 
      }

      // Lancer la boîte de dialogue d'authentification biométrique native
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Déverrouillez Aina pour accéder aux dossiers médicaux chiffrés',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true, // Forcer l'empreinte/face (pas de PIN)
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("Erreur globale lors de l'authentification biométrique : \$e");
      return false;
    }
  }
}
