import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/ambulance_model.dart';
import '../../data/models/hopital_model.dart';
import '../../data/models/pharmacie_model.dart';
import '../../domain/services/emergency_service.dart';

class EmergencyHubScreen extends StatefulWidget {
  const EmergencyHubScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  bool _isLoading = true;

  // Couleurs de la charte graphique Aina
  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color pediatricBlue = Color(0xFF4FC3F7);
  static const Color redEmergency = Color(0xFFFF5252);
  static const Color whiteCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _emergencyService.loadEmergencyData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Nettoyer le numéro pour enlever les espaces éventuels
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de lancer l'appel pour $phoneNumber"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildCallButton(List<String> contacts, Color color) {
    if (contacts.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.phone, color: color),
        onPressed: () {
          // S'il y a plusieurs numéros, on peut ouvrir un bottom sheet
          // Pour faire simple ici, on appelle le premier numéro
          _makePhoneCall(contacts.first);
        },
      ),
    );
  }

  Widget _buildPharmacieCard(PharmacieModel pharmacie) {
    return Card(
      color: whiteCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_pharmacy, color: primaryGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacie.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(pharmacie.adresse, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(pharmacie.commune, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    pharmacie.contacts.join("  •  "), 
                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            _buildCallButton(pharmacie.contacts, primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHopitalCard(HopitalModel hopital) {
    // Vérification des pôles pédiatriques cibles
    final isPediatricHub = hopital.nom.toLowerCase().contains('befelatanana') || 
                           hopital.nom.toLowerCase().contains('pavillon sainte fleur');

    return Card(
      color: whiteCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPediatricHub ? 4 : 2,
      shadowColor: isPediatricHub ? pediatricBlue.withOpacity(0.2) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isPediatricHub ? const BorderSide(color: pediatricBlue, width: 2) : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPediatricHub ? pediatricBlue.withOpacity(0.1) : redEmergency.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_hospital, color: isPediatricHub ? pediatricBlue : redEmergency, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hopital.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(hopital.adresse, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        hopital.contacts.join("  •  "), 
                        style: TextStyle(color: isPediatricHub ? pediatricBlue : redEmergency, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (hopital.note != null && hopital.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPediatricHub ? pediatricBlue.withOpacity(0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            hopital.note!,
                            style: TextStyle(
                              color: isPediatricHub ? pediatricBlue : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: isPediatricHub ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                _buildCallButton(hopital.contacts, isPediatricHub ? pediatricBlue : redEmergency),
              ],
            ),
          ),
          if (isPediatricHub)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: pediatricBlue,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), topRight: Radius.circular(20)),
                ),
                child: const Text(
                  "Pôle Pédiatrique",
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceCard(AmbulanceModel ambulance) {
    return Card(
      color: whiteCard,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.airport_shuttle, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ambulance.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(ambulance.adresse, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    ambulance.contacts.join("  •  "), 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            _buildCallButton(ambulance.contacts, Colors.orange),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: creamBackground,
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    final pharmacies = _emergencyService.getAllPharmacies();
    final hopitaux = _emergencyService.getAllHopitaux();
    final ambulances = _emergencyService.getAllAmbulances();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: creamBackground,
        appBar: AppBar(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text("Urgences Médicales", style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.local_pharmacy), text: "Pharmacies de Garde"),
              Tab(icon: Icon(Icons.local_hospital), text: "Hôpitaux & Cliniques"),
              Tab(icon: Icon(Icons.airport_shuttle), text: "Ambulances & Secours"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet: Pharmacies
            ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: pharmacies.length,
              itemBuilder: (context, index) => _buildPharmacieCard(pharmacies[index]),
            ),
            // Onglet: Hôpitaux
            ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: hopitaux.length,
              itemBuilder: (context, index) => _buildHopitalCard(hopitaux[index]),
            ),
            // Onglet: Ambulances
            ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: ambulances.length,
              itemBuilder: (context, index) => _buildAmbulanceCard(ambulances[index]),
            ),
          ],
        ),
      ),
    );
  }
}

