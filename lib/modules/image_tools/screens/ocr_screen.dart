import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/models/note_model.dart';

class OCRScreen extends ConsumerStatefulWidget {
  const OCRScreen({super.key});

  @override
  ConsumerState<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends ConsumerState<OCRScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _extractedText = "";
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _extractedText = "";
      });
      _processImage(image.path);
    }
  }

  Future<void> _processImage(String path) async {
    // Verificação de plataforma simples para evitar crash em Windows/Web
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _extractedText = "O OCR via ML Kit está disponível apenas em Android e iOS neste momento.\n\nPara Windows, seria necessário utilizar uma biblioteca diferente (ex: Tesseract) ou uma API Cloud.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _extractedText = "";
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
        if (_extractedText.isEmpty) {
          _extractedText = "Nenhum texto detectado na imagem.";
        }
      });

      await textRecognizer.close();
    } catch (e) {
      setState(() {
        _extractedText = "Erro ao processar imagem: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto copiado para a área de transferência!')),
      );
    }
  }

  void _saveAsNote() {
    if (_extractedText.isEmpty) return;
    final note = Note(
      title: 'OCR ${DateTime.now().toString().substring(0, 16)}',
      content: _extractedText,
      type: NoteType.text,
    );
    ref.read(notesProvider.notifier).addNote(note);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota criada com o texto extraído')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Texto (OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecionar imagem para extrair texto',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_extractedText.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Texto Extraído:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyToClipboard,
                            tooltip: 'Copiar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.save_alt),
                            onPressed: _saveAsNote,
                            tooltip: 'Salvar como Nota',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: SelectableText(
                      _extractedText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
