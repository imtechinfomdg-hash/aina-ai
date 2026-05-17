import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/services/llama_service.dart';
import '../../domain/services/knowledge_base_service.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({Key? key}) : super(key: key);

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  String _extractedRawText = "";
  Map<String, String>? _extractedMedicalInfo;
  
  final _ocrService = OcrService();
  late final LlamaService _llamaService;

  @override
  void initState() {
    super.initState();
    _llamaService = LlamaService(KnowledgeBaseService());
    _initLlama();
  }
  
  Future<void> _initLlama() async {
    try {
      await _llamaService.initializeModel();
    } catch (e) {
      print("Erreur initialisation Llama: \$e");
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _extractedRawText = "";
        _extractedMedicalInfo = null;
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. OCR (Lecture du texte sur l'image)
      final rawText = await _ocrService.extractTextFromImage(_imageFile!);
      setState(() {
        _extractedRawText = rawText;
      });

      if (rawText.trim().isNotEmpty) {
        // 2. Extraction NER via Llama
        final info = await _llamaService.extractMedicalInfo(rawText);
        setState(() {
          _extractedMedicalInfo = info;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de traitement: \$e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Numérisation de document'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFFFAF1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.none),
                ),
                child: const Center(
                  child: Text("Aucun document sélectionné", style: TextStyle(color: Colors.grey)),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Prendre une photo"),
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Galerie"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C), foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 8),
                    Text("Analyse par l'IA en cours..."),
                  ],
                ),
              )
            else if (_extractedMedicalInfo != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informations Extrait (IA NER):",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32)),
                      ),
                      const Divider(),
                      Text("Nom du patient: \$(_extractedMedicalInfo!['patient_name'] ?? 'Non trouvé')", style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text("Date: \$(_extractedMedicalInfo!['date'] ?? 'Non trouvée')", style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text("Diagnostic: \$(_extractedMedicalInfo!['diagnosis'] ?? 'Non trouvé')", style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            if (!_isProcessing && _extractedRawText.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text("Texte Brut OCR :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(_extractedRawText, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
