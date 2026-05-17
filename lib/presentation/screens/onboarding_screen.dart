import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../domain/services/localization_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep green
  static const Color creamBackground = Colors.white; 
  
  bool _accepted = false;
  String _selectedLang = LocalizationService().currentLanguage;

  Future<void> _saveConsent() async {
    if (kIsWeb) {
      Navigator.pushReplacementNamed(context, '/biometric');
      return;
    }
    
    const storage = FlutterSecureStorage();
    await storage.write(key: 'gdpr_consent', value: 'true');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/biometric');
    }
  }

  Widget _buildLanguageButton(String lang) {
    // Determine language display name (e.g., MG for Malagasy, FR for French, EN for English).
    // Or just use the code itself.
    bool isSelected = _selectedLang == lang;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLang = lang;
          LocalizationService().setLanguage(lang);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          lang,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: Image.asset(
              'assets/images/baby_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE5F5F4), Color(0xFFC0EBE8)],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Gradient fade to white
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.4 - 50,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top header language selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLanguageButton("MG"),
                      const SizedBox(width: 8),
                      _buildLanguageButton("EN"),
                      const SizedBox(width: 8),
                      _buildLanguageButton("FR"),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Aina
                      const Text(
                        "AINA",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: primaryGreen,
                          letterSpacing: 4.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        LocalizationService().translate('care_for_baby'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        LocalizationService().translate('onboarding_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54, // lighter grey
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Checkbox and Agreement Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.grey.shade400),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _accepted,
                                activeColor: primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() => _accepted = val ?? false);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _accepted = !_accepted);
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                                  children: [
                                    TextSpan(text: LocalizationService().translate('agree_to')),
                                    TextSpan(
                                      text: LocalizationService().translate('terms'),
                                      style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: LocalizationService().translate('and_consent'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _accepted ? _saveConsent : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                LocalizationService().translate('get_started'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: primaryGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
