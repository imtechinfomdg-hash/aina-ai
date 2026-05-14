import 'package:flutter/material.dart';
import '../../data/models/child_model.dart';
import '../../data/models/vaccine_model.dart';
import '../../domain/services/vaccination_service.dart';
import 'package:intl/intl.dart';

class VaccineTrackerScreen extends StatefulWidget {
  final ChildModel child;

  const VaccineTrackerScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<VaccineTrackerScreen> createState() => _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends State<VaccineTrackerScreen> {
  final VaccinationService _vaccinationService = VaccinationService();
  List<VaccineModel> _vaccines = [];
  bool _isLoading = true;

  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color pediatricBlue = Color(0xFF4FC3F7);
  static const Color redEmergency = Color(0xFFFF5252);
  static const Color orangeWarning = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _loadVaccines();
  }

  Future<void> _loadVaccines() async {
    setState(() => _isLoading = true);
    final vaccines = await _vaccinationService.getVaccines(widget.child);
    setState(() {
      _vaccines = vaccines;
      _isLoading = false;
    });
  }

  Future<void> _handleCheckboxChanged(VaccineModel vaccine, bool? value) async {
    if (value == true) {
      // Ouvre un pop-up pour choisir la date de l'injection
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: widget.child.birthDate,
        lastDate: DateTime.now(),
        helpText: "Date d'administration du vaccin",
        cancelText: "Annuler",
        confirmText: "Enregistrer",
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryGreen, 
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        await _vaccinationService.markVaccineAdministered(vaccine, pickedDate);
        _loadVaccines();
      }
    } else {
      // Décocher
      await _vaccinationService.unmarkVaccine(vaccine);
      _loadVaccines();
    }
  }

  Widget _buildTimelineItem(VaccineModel vaccine) {
    final status = _vaccinationService.getStatus(vaccine);
    final isLate = status == VaccineStatus.late;
    final isCompleted = status == VaccineStatus.completed;

    Color itemColor;
    Color bgColor;
    if (isCompleted) {
      itemColor = primaryGreen;
      bgColor = primaryGreen.withOpacity(0.05);
    } else if (isLate) {
      itemColor = redEmergency;
      bgColor = redEmergency.withOpacity(0.05);
    } else {
      itemColor = orangeWarning;
      bgColor = Colors.white;
    }

    final dateText = isCompleted
        ? "Fait le: ${DateFormat('dd MMMM yyyy', 'fr_FR').format(vaccine.dateAdministered!)}"
        : "Prévu le: ${DateFormat('dd MMMM yyyy', 'fr_FR').format(vaccine.datePlanned)}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline drawing
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(width: 3, color: isCompleted ? primaryGreen.withOpacity(0.5) : Colors.grey[300]),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? primaryGreen : Colors.white,
                    border: Border.all(color: itemColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withOpacity(0.3),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                Expanded(
                  flex: 3,
                  child: Container(width: 3, color: isCompleted ? primaryGreen.withOpacity(0.5) : Colors.grey[300]),
                ),
              ],
            ),
          ),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Card(
                elevation: isLate && !isCompleted ? 3 : 1,
                color: bgColor,
                shadowColor: itemColor.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  side: isLate && !isCompleted 
                        ? BorderSide(color: redEmergency.withOpacity(0.5), width: 1.5) 
                        : BorderSide(color: Colors.grey.shade200, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vaccine.vaccineName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isCompleted ? Colors.black54 : Colors.black87,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: itemColor),
                                const SizedBox(width: 6),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isLate && !isCompleted ? redEmergency : Colors.grey[700],
                                    fontWeight: isLate ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isLate && !isCompleted)
                              Container(
                                margin: const EdgeInsets.only(top: 8.0),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: redEmergency.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: redEmergency, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "À rattraper",
                                      style: TextStyle(fontSize: 12, color: redEmergency, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isCompleted ? primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
                          shape: BoxShape.circle
                        ),
                        child: Checkbox(
                          value: vaccine.isCompleted,
                          activeColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => _handleCheckboxChanged(vaccine, val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: Text("Carnet PEV: ${widget.child.firstName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: pediatricBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: pediatricBlue))
          : _vaccines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vaccines, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Aucun vaccin trouvé.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  )
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _vaccines.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(_vaccines[index]);
                  },
                ),
    );
  }
}
