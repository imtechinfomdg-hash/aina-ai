import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/child_model.dart';
import '../../data/models/constante_model.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/models/medication_reminder_model.dart';

class PdfExportService {
  static Future<void> exportChildRecord(
    ChildModel child,
    List<ConstanteModel> constantes,
    List<VaccineModel> vaccines,
    List<MedicationReminderModel> medications,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
            ),
            child: pw.Text("Carnet de Santé Aina", style: const pw.TextStyle(color: PdfColors.grey, fontSize: 12)),
          );
        },
        build: (pw.Context context) {
          return [
            _buildHeader(child),
            pw.SizedBox(height: 20),
            _buildConstantes(constantes),
            pw.SizedBox(height: 20),
            _buildVaccines(vaccines),
            pw.SizedBox(height: 20),
            _buildMedications(medications),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              "Généré par l'application Aina le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\\nDocument local et confidentiel",
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          );
        },
      ),
    );

    if (kIsWeb) {
      // In web, you would normally download the file using html.AnchorElement
      // but we leave this unimplemented for now as Aina is primarily Android offline.
      print("Export PDF non supporté sur Web via PathProvider");
      return;
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/carnet_sante_${child.firstName.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Partager ou ouvrir le fichier
    await Share.shareXFiles([XFile(file.path)], text: 'Carnet de santé de ${child.firstName}');
  }

  static pw.Widget _buildHeader(ChildModel child) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Dossier Médical', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nom: ${child.firstName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date de naissance: ${child.birthDate}'),
                  pw.Text('Sexe: ${child.gender}'),
                ]
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Poids naissance: ${child.weight} kg'),
                  pw.Text('Taille naissance: ${child.height} cm'),
                ]
              )
            ]
          )
        )
      ],
    );
  }

  static pw.Widget _buildConstantes(List<ConstanteModel> constantes) {
    if (constantes.isEmpty) {
      return pw.Text('Aucune constante médicale enregistrée.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Évolution des Constantes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Date', 'Poids (kg)', 'Taille (cm)', 'Température (°C)'],
          data: constantes.map((c) => [
            DateFormat('dd/MM/yyyy').format(c.date),
            c.poids.toString(),
            c.taille.toString(),
            c.temperature.toString()
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          cellAlignment: pw.Alignment.center,
        ),
      ]
    );
  }

  static pw.Widget _buildVaccines(List<VaccineModel> vaccines) {
    if (vaccines.isEmpty) {
       return pw.Text('Aucun vaccin enregistré.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Historique Vaccinal (PEV)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Vaccin', 'Date Prévue', 'Statut', 'Date d\\'Administration'],
          data: vaccines.map((v) => [
            v.vaccineName,
            DateFormat('dd/MM/yyyy').format(v.datePlanned),
            v.isCompleted ? 'Fait' : 'À faire',
            v.dateAdministered != null ? DateFormat('dd/MM/yyyy').format(v.dateAdministered!) : '-',
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green600),
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          cellAlignment: pw.Alignment.center,
        ),
      ]
    );
  }

  static pw.Widget _buildMedications(List<MedicationReminderModel> medications) {
    if (medications.isEmpty) {
       return pw.Text('Aucun traitement en cours.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Traitements / Pilulier', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
           headers: ['Médicament', 'Dosage', 'Heure', 'Statut'],
           data: medications.map((m) => [
             m.medName,
             m.dosage,
             DateFormat('HH:mm').format(m.time),
             m.isActive ? 'Actif' : 'Inactif',
           ]).toList(),
           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
           headerDecoration: const pw.BoxDecoration(color: PdfColors.orange500),
           rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
           cellAlignment: pw.Alignment.center,
        )
      ]
    );
  }
}
