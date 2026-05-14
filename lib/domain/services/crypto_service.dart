import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service de chiffrement local (Local-first)
/// Sécurise les données avec ECC (Elliptic Curve Cryptography) et AES-GCM 256
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  
  // Algorithme de chiffrement symétrique fort (AES-GCM 256 bits)
  final _aesGcm = AesGcm.with256bits();
  
  // Clé en mémoire vive après déverrouillage (NE JAMAIS ECRIRE EN CLAIR DANS LES LOGS)
  SecretKey? _aesKey;
  
  // Chemins de stockage pour les composants cryptographiques
  static const String _wrappedAesKeyPath = 'aina_wrapped_aes_key';
  static const String _eccPrivateKeyPath = 'aina_ecc_private_key';
  static const String _eccPublicKeyPath = 'aina_ecc_public_key';
  static const String _ephemeralPubKeyPath = 'aina_ephemeral_pub_key';
  static const String _noncePath = 'aina_aes_wrap_nonce';
  static const String _macPath = 'aina_aes_wrap_mac';

  /// Initialisation et déverrouillage de la clé AES via l'empreinte digitale
  Future<bool> initializeAndUnlock() async {
    bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    
    if (canAuthenticate) {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Déverrouillez pour accéder aux données de santé de votre enfant',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!didAuthenticate) {
        throw Exception("Authentification biométrique requise pour déchiffrer la base de données.");
      }
    }

    // Vérifie si on a déjà généré les clés
    final privateKeyStr = await _secureStorage.read(key: _eccPrivateKeyPath);
    if (privateKeyStr == null) {
      await _generateKeys();
    }
    
    await _unwrapAesKey();
    return true;
  }

  /// Génère une paire de clés asymétriques ECC (X25519) et une clé AES
  /// Enveloppe (wrap) la clé AES avec ECDH
  Future<void> _generateKeys() async {
    // 1. Générer une paire de clés ECC (X25519 pour ECDH)
    final eccGen = X25519();
    final keyPair = await eccGen.newKeyPair();
    
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    
    // Stocker la clé privée dans le Secure Storage (compartiment matériel sécurisé)
    await _secureStorage.write(key: _eccPrivateKeyPath, value: base64Encode(privateKeyBytes));
    await _secureStorage.write(key: _eccPublicKeyPath, value: base64Encode(publicKey.bytes));
    
    // 2. Générer la clé AES-GCM 256 bits pour chiffrer la base de données et les textes
    final newAesKey = await _aesGcm.newSecretKey();
    final aesKeyBytes = await newAesKey.extractBytes();
    
    // 3. Chiffrer (Wrap) la clé AES via un ECDH éphémère
    final ephemeralKeyPair = await eccGen.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();
    
    final sharedSecret = await eccGen.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: publicKey,
    );
    
    // Dérivation de clé HKDF
    final kdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final wrappingKey = await kdf.deriveKey(secretKey: sharedSecret, nonce: [1, 2, 3]);
    
    // Enveloppement AES-GCM
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      aesKeyBytes,
      secretKey: wrappingKey,
      nonce: nonce,
    );
    
    // On conserve la clé éphémère publique pour le futur déchiffrement (+ le ciphertext de la clé AES)
    await _secureStorage.write(key: _ephemeralPubKeyPath, value: base64Encode(ephemeralPublicKey.bytes));
    await _secureStorage.write(key: _wrappedAesKeyPath, value: base64Encode(secretBox.cipherText));
    await _secureStorage.write(key: _noncePath, value: base64Encode(secretBox.nonce));
    await _secureStorage.write(key: _macPath, value: base64Encode(secretBox.mac.bytes));
    
    _aesKey = newAesKey;
  }

  /// Déchiffre (Unwrap) la clé AES en utilisant la clé ECC privée
  Future<void> _unwrapAesKey() async {
    final privateKeyB64 = await _secureStorage.read(key: _eccPrivateKeyPath);
    final publicKeyB64 = await _secureStorage.read(key: _eccPublicKeyPath);
    final ephemeralPubB64 = await _secureStorage.read(key: _ephemeralPubKeyPath);
    final wrappedAesB64 = await _secureStorage.read(key: _wrappedAesKeyPath);
    final nonceB64 = await _secureStorage.read(key: _noncePath);
    final macB64 = await _secureStorage.read(key: _macPath);
    
    if (privateKeyB64 == null || wrappedAesB64 == null || ephemeralPubB64 == null) {
      throw Exception("Données de chiffrement manquantes ou corrompues. Impossible d'unwrap.");
    }
    
    final eccGen = X25519();
    final myKeyPair = SimpleKeyPairData(
      base64Decode(privateKeyB64),
      publicKey: SimplePublicKey(base64Decode(publicKeyB64!), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    
    final ephemeralPub = SimplePublicKey(base64Decode(ephemeralPubB64), type: KeyPairType.x25519);
    
    // 1. Recalculer le secret partagé (ECDH)
    final sharedSecret = await eccGen.sharedSecretKey(keyPair: myKeyPair, remotePublicKey: ephemeralPub);
    final kdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final unwrappingKey = await kdf.deriveKey(secretKey: sharedSecret, nonce: [1, 2, 3]);
    
    // 2. Déchiffrer la clé AES
    final secretBox = SecretBox(
      base64Decode(wrappedAesB64),
      nonce: base64Decode(nonceB64!),
      mac: Mac(base64Decode(macB64!)),
    );
    
    final aesKeyBytes = await _aesGcm.decrypt(secretBox, secretKey: unwrappingKey);
    _aesKey = SecretKey(aesKeyBytes);
  }

  /// Retourne la clé symétrique brute en Base64 pour déverrouiller SQFlite SQLCipher
  Future<String> getDatabaseEncryptionKey() async {
    if (_aesKey == null) {
      throw Exception("La clé AES principale n'est pas encore en mémoire. Avez-vous déverrouillé l'application ?");
    }
    final bytes = await _aesKey!.extractBytes();
    return base64Encode(bytes);
  }

  /// Chiffre un texte sensible (UTF-8) avec AES-GCM 256 à la volée
  Future<String> encryptData(String plainText) async {
    if (_aesKey == null) {
      throw Exception("Clé AES non prête.");
    }
    final plainBytes = utf8.encode(plainText);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(plainBytes, secretKey: _aesKey!, nonce: nonce);
    
    // Combine nonce + tag(MAC) + ciphertext pour le stockage
    final combined = [...nonce, ...secretBox.mac.bytes, ...secretBox.cipherText];
    return base64Encode(combined);
  }

  /// Déchiffre un texte (UTF-8) chiffré précédemment par encryptData
  Future<String> decryptData(String combinedBase64) async {
    if (_aesKey == null) {
      throw Exception("Clé AES non prête.");
    }
    final combined = base64Decode(combinedBase64);
    
    const nonceLength = 12; // Standard AES-GCM nonce
    const macLength = 16;  // Standard AES-GCM MAC
    
    if (combined.length < nonceLength + macLength) {
      throw Exception("Données chiffrées invalides.");
    }
    
    final nonce = combined.sublist(0, nonceLength);
    final macBytes = combined.sublist(nonceLength, nonceLength + macLength);
    final cipherText = combined.sublist(nonceLength + macLength);
    
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final plainBytes = await _aesGcm.decrypt(secretBox, secretKey: _aesKey!);
    
    return utf8.decode(plainBytes);
  }
}
