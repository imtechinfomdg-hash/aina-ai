import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/child_model.dart';
import '../../data/models/medication_reminder_model.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/llama_service.dart';
import '../../domain/services/knowledge_base_service.dart';

class MedicationTrackerScreen extends StatefulWidget {
  final ChildModel child;
  const MedicationTrackerScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  late LlamaService _llamaService;
  
  List<MedicationReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _llamaService = LlamaService(KnowledgeBaseService());
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    _reminders = await _dbHelper.getRemindersForChild(widget.child.id!);
    setState(() => _isLoading = false);
  }

  Future<void> _toggleReminder(MedicationReminderModel reminder, bool isActive) async {
    final updated = reminder.copyWith(isActive: isActive);
    await _dbHelper.updateReminder(updated);
    
    if (isActive) {
      await _notificationService.scheduleMedicationReminder(updated);
    } else {
      if (updated.id != null) {
        await _notificationService.cancelReminder(updated.id!);
      }
    }
    _loadReminders();
  }

  Future<void> _deleteReminder(MedicationReminderModel reminder) async {
    if (reminder.id != null) {
      await _dbHelper.deleteReminder(reminder.id!);
      await _notificationService.cancelReminder(reminder.id!);
      _loadReminders();
    }
  }

  Future<void> _showReminderSheet({MedicationReminderModel? existingReminder}) async {
    final titleController = TextEditingController(text: existingReminder?.medName ?? "");
    final dosageController = TextEditingController(text: existingReminder?.dosage ?? "");
    TimeOfDay selectedTime = existingReminder != null 
        ? TimeOfDay.fromDateTime(existingReminder.time)
        : TimeOfDay.now();

    bool _isChecking = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
             padding: EdgeInsets.only(
               bottom: MediaQuery.of(context).viewInsets.bottom + 20,
               top: 20,
               left: 20,
               right: 20,
             ),
             decoration: const BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
             ),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(existingReminder != null ? "Modifier Traitement" : "Nouveau Traitement", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 20),
                 TextField(
                   controller: titleController,
                   decoration: const InputDecoration(labelText: "Nom du médicament", border: OutlineInputBorder()),
                 ),
                 const SizedBox(height: 12),
                 TextField(
                   controller: dosageController,
                   decoration: const InputDecoration(labelText: "Dosage (ex: 1/2 cuillère, 5ml)", border: OutlineInputBorder()),
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: OutlinedButton.icon(
                         onPressed: _isChecking ? null : () async {
                           if (titleController.text.trim().isEmpty) return;
                           
                           setModalState(() { _isChecking = true; });
                           final tempReminder = MedicationReminderModel(
                             id: existingReminder?.id,
                             enfantId: widget.child.id!,
                             medName: titleController.text.trim(),
                             dosage: dosageController.text.trim(),
                             time: DateTime.now(),
                             isActive: existingReminder?.isActive ?? true,
                           );
                           String? warning;
                           try {
                             warning = await _llamaService.checkDrugInteraction(
                               _reminders.where((r) => r.id != tempReminder.id).toList(), 
                               tempReminder
                             );
                           } catch (e) {
                             warning = "Erreur de vérification: $e";
                           }
                           setModalState(() { _isChecking = false; });
                           
                           if (context.mounted) {
                             if (warning != null) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(warning), backgroundColor: Colors.red));
                             } else {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Aucune interaction identifiée."), backgroundColor: Colors.green));
                             }
                           }
                         },
                         icon: _isChecking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.security),
                         label: const Text("Vérifier compatibilité"),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 ListTile(
                   title: const Text("Heure du rappel"),
                   trailing: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   onTap: () async {
                     final TimeOfDay? time = await showTimePicker(context: context, initialTime: selectedTime);
                     if (time != null) {
                       setModalState(() => selectedTime = time);
                     }
                   },
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                 ),
                 const SizedBox(height: 20),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                     onPressed: _isChecking ? null : () async {
                       if (titleController.text.trim().isEmpty || dosageController.text.trim().isEmpty) return;
                       
                       // Create dummy time with today
                       final now = DateTime.now();
                       final reminderTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                       
                       final newReminder = MedicationReminderModel(
                         id: existingReminder?.id,
                         enfantId: widget.child.id!,
                         medName: titleController.text.trim(),
                         dosage: dosageController.text.trim(),
                         time: reminderTime,
                         isActive: existingReminder?.isActive ?? true,
                       );

                       // Vérification de sécurité locale (Interactions)
                       setModalState(() { _isChecking = true; });
                       String? warning;
                       try {
                         warning = await _llamaService.checkDrugInteraction(
                           _reminders.where((r) => r.id != newReminder.id).toList(), 
                           newReminder
                         );
                       } catch (e) {
                         warning = "Erreur de vérification: $e";
                       }
                       setModalState(() { _isChecking = false; });
                       
                       if (warning != null && context.mounted) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Alerte d'Interaction !"),
                              content: Text(warning, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Enregistrer quand même", style: TextStyle(color: Colors.red))),
                              ],
                            )
                          );
                          if (confirm != true) return;
                       }
                       
                       if (context.mounted) {
                         Navigator.pop(context); // Close sheet
                         // Save to DB
                         if (newReminder.id != null) {
                           await _dbHelper.updateReminder(newReminder);
                           await _notificationService.scheduleMedicationReminder(newReminder);
                         } else {
                           final id = await _dbHelper.addReminder(newReminder);
                           final savedReminder = newReminder.copyWith(id: id);
                           await _notificationService.scheduleMedicationReminder(savedReminder);
                         }
                         _loadReminders();
                       }
                     },
                     child: _isChecking 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Text("Planifier", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                 )
               ],
             ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF1), // Cream bg
      appBar: AppBar(
        title: Text("Pilulier - ${widget.child.firstName}"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReminderSheet,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Aucun traitement en cours pour ${widget.child.firstName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: reminder.isActive ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication, color: reminder.isActive ? const Color(0xFF2E7D32) : Colors.grey),
                    ),
                    title: Text(reminder.medName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Dosage: ${reminder.dosage}"),
                        const SizedBox(height: 4),
                        Text("Heure: ${DateFormat('HH:mm').format(reminder.time)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue800)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: reminder.isActive,
                          onChanged: (val) => _toggleReminder(reminder, val),
                          activeColor: const Color(0xFF2E7D32),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showReminderSheet(existingReminder: reminder),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReminder(reminder),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
