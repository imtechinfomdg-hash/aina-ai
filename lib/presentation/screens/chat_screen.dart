import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/services/knowledge_base_service.dart';
import '../../domain/services/llama_service.dart';
import '../../domain/services/hardware_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  final ImagePicker _imagePicker = ImagePicker();

  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;

  late KnowledgeBaseService _kbService;
  late LlamaService _llamaService;
  bool _isServicesReady = false;

  late AnimationController _waveController;

  static const Color creamBackground = Color(0xFFFFFAF1);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color pediatricBlue = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _initTts();
    _initSpeech();
    _initServices();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => print('onError: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage("fr-FR");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _flutterTts.setErrorHandler((msg) {
        print("TTS Error: $msg");
      });
    } catch (e) {
      print("Erreur initialisation TTS: $e");
    }
  }

  Future<void> _initServices() async {
    _kbService = KnowledgeBaseService();
    await _kbService.loadKnowledgeBase();
    
    _llamaService = LlamaService(_kbService);
    
    final hardwareService = HardwareService();
    final useLightweightModel = await hardwareService.shouldUseLightweightModel();
    if (useLightweightModel) {
      print("Chargement de la version allégée du modèle LLM 1B (RAM < 3Go)...");
    }

    await _llamaService.initializeModel();
    
    if (mounted) {
      setState(() {
        _isServicesReady = true;
        _messages.add(ChatMessage(
          text: "Salama! Izaho no Aina. Inona no mety hanampiako anao momba ny fahasalaman'ny zanakao?", 
          isUser: false
        ));
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      bool init = await _speechToText.initialize();
      if (!init) return;
    }
    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
          // Move cursor to end
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        });
      },
      localeId: 'fr_FR', // Fallback local, speech_to_text typically uses device default
    );
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speechToText.stop();
  }

  Future<void> _scanImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Fakantsary (Caméra)"),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Sary anaty telefaona (Galerie)"),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isTyping = true);

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      setState(() {
        _isTyping = false;
        if (recognizedText.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tsy nisy soratra hita tamin'ny sary.")),
          );
        } else {
          // Pre-fill text field
          String currentText = _textController.text;
          _textController.text = currentText.isEmpty 
              ? recognizedText.text 
              : "$currentText\n${recognizedText.text}";
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nisy olana nandritra ny fitiliana ny sary: $e")),
        );
      }
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    
    _scrollToBottom();

    try {
      final response = await _llamaService.generateTriageResponse(text, 'mg');
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: response, isUser: false));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: "Miala tsiny, nisy olana ara-teknika: $e", isUser: false));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Tsy afaka mamaky teny: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isUser ? pediatricBlue.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (!isUser) // Bouton TTS (Hihaino) uniquement pour les réponses de l'IA (Aina)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: GestureDetector(
                  onTap: () => _speak(message.text),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.volume_up, size: 14, color: primaryGreen),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Hihaino",
                        style: TextStyle(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Triage IA (Aina)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 4. Bandeau d'avertissement permanent en haut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Torohevitra ankapobeny ihany ity, manatona dokotera hatrany.",
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          
          // Zone de messages
          Expanded(
            child: !_isServicesReady 
              ? const Center(child: CircularProgressIndicator(color: primaryGreen))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
          ),
          
          // Indicateur de saisie IA (attente génération de tokens)
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Text("Mieritreritra...", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 14)),
                ],
              ),
            ),
            
          // Barre d'état inférieure (champ de texte + appareil photo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: primaryGreen, size: 22),
                      onPressed: _scanImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Soraty eto ny olana...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      ),
                      onSubmitted: _handleSubmitted,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) => _startListening(),
                        onLongPressEnd: (_) => _stopListening(),
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return CircleAvatar(
                              backgroundColor: _isListening ? Colors.red : Colors.grey.shade200,
                              radius: _isListening 
                                ? 24 + (_waveController.value * 4) // Animation légère
                                : 24,
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none, 
                                color: _isListening ? Colors.white : primaryGreen, 
                                size: 20
                              ),
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: primaryGreen,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () => _handleSubmitted(_textController.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
