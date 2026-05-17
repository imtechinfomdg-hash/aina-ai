import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'domain/services/biometric_security_service.dart';
import 'domain/services/hardware_service.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/localization_service.dart';
import 'domain/services/vaccination_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
    
    // Initialize localization
    await LocalizationService().init();
    
    // Initialise les notifications locales
    await NotificationService().init();
    
    // Programme les rappels de vaccination
    await VaccinationService().scheduleAllUpcomingVaccinations();
    
    // 2. Évaluation matérielle (RAM)
    final hardwareService = HardwareService();
    try {
      final useLightweight = await hardwareService.shouldUseLightweightModel();
      if (kDebugMode) {
        print("Hardware evaluation: use lightweight model = $useLightweight");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error evaluating RAM: $e");
      }
    }
    
    // 3. Jetons de consentement RGPD
    String initialRoute = '/onboarding';
    try {
      if (!kIsWeb) {
        const storage = FlutterSecureStorage();
        final consent = await storage.read(key: 'gdpr_consent');
        if (consent == 'true') {
          initialRoute = '/biometric';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error reading secure storage: $e");
      }
    }

    runApp(ErrorCatcher(child: AinaApp(initialRoute: initialRoute)));
  }, (error, stack) {
    if (kDebugMode) {
      print('CRASH: $error');
    }
  });
}

class ErrorCatcher extends StatefulWidget {
  final Widget child;
  const ErrorCatcher({Key? key, required this.child}) : super(key: key);

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = details.exceptionAsString());
      });
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = error.toString());
      });
      return true;
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('CRASH: $_error', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class AinaApp extends StatelessWidget {
  final String initialRoute;
  
  const AinaApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aina Infantile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/biometric': (context) => const AuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }

    final bioService = BiometricSecurityService();
    final success = await bioService.authenticateUser();
    
    if (mounted) {
      if (success) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      } else {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFAF1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 80, color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text("Authentification sécurisée...", style: TextStyle(color: Color(0xFF2E7D32))),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFAF1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text("Accès refusé. Empreinte requise.", style: TextStyle(fontSize: 18, color: Colors.black87)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                onPressed: () => _checkBiometric(),
                child: const Text("Réessayer"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text("Quitter l'application", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}