import 'package:flutter/material.dart';
import 'emergency_hub_screen.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({Key? key}) : super(key: key);

  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color redEmergency = Color(0xFFDC2626);

  void _navigateToDetail(BuildContext context, String title, List<Map<String, dynamic>> steps) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FirstAidDetailScreen(title: title, steps: steps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Gestes de Premiers Secours", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: redEmergency,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyHubScreen()),
          );
        },
        backgroundColor: redEmergency,
        icon: const Icon(Icons.maps_ugc_rounded), // phone icon logic
        label: const Text("Urgences", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEmergencyCard(
            context,
            "ÉTOUFFEMENT / OBSTRUCTION",
            "ZAZA SENPOTRA",
            Icons.healing,
            redEmergency,
            [
              {
                "image": "assets/images/secours/etouffement_step1.png",
                "mg": "Apetraho mitsinkafona amin'ny sandrinao ny zaza (< 1 taona), ny tarehy mitodika any ambany, ny loha ambany kokoa noho ny tratra.",
                "fr": "Placer le nourrisson (< 1 an) à califourchon sur votre avant-bras, face vers le sol, la tête plus basse que le thorax.",
                "en": "Place the infant (< 1 year) straddling your forearm, face down, head lower than the chest."
              },
              {
                "image": "assets/images/secours/etouffement_step2.png",
                "mg": "Omeo kapoka 5 mafitrafitra eo anelanelan'ny taolan-tsoroky ny zaza, amin'ny vodin-tanana.",
                "fr": "Donner 5 claques fermes dans le dos, entre les deux omoplates, avec le talon de la main.",
                "en": "Give 5 firm back blows between the shoulder blades with the heel of your hand."
              },
              {
                "image": "assets/images/secours/etouffement_step3.png",
                "mg": "Raha tsy mivoaka ilay zavatra, tsindrio in-5 ny afovoan'ny tratrany, amin'ny rantsan-tanana 2.",
                "fr": "Si l'objet n'est pas expulsé, effectuer 5 compressions thoraciques au centre de la poitrine avec 2 doigts.",
                "en": "If the object is not expelled, perform 5 chest thrusts in the center of the chest with 2 fingers."
              }
            ],
          ),
          const SizedBox(height: 16),
          _buildEmergencyCard(
            context,
            "CONVULSIONS FÉBRILES",
            "REBI-TAZO",
            Icons.warning_amber_rounded,
            primaryGreen,
            [
              {
                "image": "assets/images/secours/convulsion_step1.png",
                "mg": "Aza asiana zavatra ao am-bavan'ny zaza na manakana ny fihetsehany.",
                "fr": "Ne rien mettre dans la bouche et ne pas tenter de bloquer ses mouvements.",
                "en": "Do not put anything in the mouth and do not attempt to restrain movements."
              },
              {
                "image": "assets/images/secours/convulsion_step2.png",
                "mg": "Ampandriho amin'ny ilany ny zaza (PLS) eo amin'ny toerana malefaka sady azo antoka.",
                "fr": "Allonger l'enfant sur le côté en Position Latérale de Sécurité (PLS) sur une surface souple.",
                "en": "Lay the child on their side in the Recovery Position (PLS) on a soft surface."
              },
              {
                "image": "assets/images/secours/convulsion_step3.png",
                "mg": "Diniho ny faharetan'ny fifanintonana ary esory ny akanjony hampidina ny hafanana.",
                "fr": "Chronométrer la crise et déshabiller l'enfant pour faire baisser la fièvre.",
                "en": "Time the seizure and undress the child to lower the fever."
              }
            ],
          ),
          const SizedBox(height: 16),
          _buildEmergencyCard(
            context,
            "DÉSHYDRATATION SÉVÈRE",
            "RITRA RANO MAFY",
            Icons.water_drop,
            redEmergency,
            [
              {
                "image": "assets/images/secours/deshydratation_step1.png",
                "mg": "Zahao ny famantarana: Maso lavaka, tsy misy ranomaso, ny hoditra eo amin'ny kibo dia mijanona ketrona > 2 segaondra.",
                "fr": "Identifier les signes : Yeux creux, absence de larmes, pli cutané sur le ventre qui reste marqué > 2 secondes.",
                "en": "Identify signs: Sunken eyes, absence of tears, skin pinch on the abdomen goes back very slowly (> 2 seconds)."
              },
              {
                "image": "assets/images/secours/deshydratation_step2.png",
                "mg": "Omeo rano SRO avy hatrany amin'ny sotro kely isaky ny 2 minitra, na dia mandoa aza ny zaza.",
                "fr": "Donner immédiatement la Solution de Réhydratation Orale (SRO) par petites cuillères toutes les 2 minutes.",
                "en": "Immediately give Oral Rehydration Solution (ORS) in small sips every 2 minutes."
              }
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(
      BuildContext context, String titleFr, String titleMg, IconData icon, Color color, List<Map<String, dynamic>> steps) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToDetail(context, titleFr, steps),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleFr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titleMg,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class FirstAidDetailScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> steps;

  const FirstAidDetailScreen({Key? key, required this.title, required this.steps}) : super(key: key);

  @override
  State<FirstAidDetailScreen> createState() => _FirstAidDetailScreenState();
}

class _FirstAidDetailScreenState extends State<FirstAidDetailScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FirstAidScreen.creamBackground,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: FirstAidScreen.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < widget.steps.length - 1) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == widget.steps.length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                if (!isLastStep)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FirstAidScreen.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Étape suivante', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (isLastStep)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FirstAidScreen.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Retour', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
        steps: widget.steps.map((step) {
          int index = widget.steps.indexOf(step);
          return Step(
            isActive: _currentStep >= index,
            state: _currentStep > index ? StepState.complete : StepState.indexed,
            title: Text(
              "Étape ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      step["image"],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.healing, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("Illustration à venir", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLangText("MG", step["mg"], FirstAidScreen.primaryGreen),
                        const Divider(height: 24),
                        _buildLangText("FR", step["fr"], Colors.black87),
                        const SizedBox(height: 12),
                        _buildLangText("EN", step["en"], Colors.black54),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLangText(String lang, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            lang,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: lang == "MG" ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
