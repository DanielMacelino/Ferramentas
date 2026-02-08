import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

class QrReaderScreen extends StatefulWidget {
  const QrReaderScreen({super.key});

  @override
  State<QrReaderScreen> createState() => _QrReaderScreenState();
}

class _QrReaderScreenState extends State<QrReaderScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _decoded;
  bool _processing = false;

  Future<void> _pick() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _decoded = null;
      });
      _decode();
    }
  }

  Future<void> _decode() async {
    if (_imageFile == null) return;
    setState(() => _processing = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) throw Exception('Imagem inválida');
      final converted = src.convert(numChannels: 4);
      final luminance = RGBLuminanceSource(
        converted.width,
        converted.height,
        converted.getBytes(order: img.ChannelOrder.rgba).buffer.asInt32List(),
      );
      final bitmap = BinaryBitmap(HybridBinarizer(luminance));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      setState(() {
        _decoded = result.text;
      });
    } catch (e) {
      setState(() {
        _decoded = 'Falha ao ler QR';
      });
    }
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Selecionar imagem com QR'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.contain)
                    : const Center(child: Text('Selecione uma imagem contendo QR')),
              ),
            ),
            const SizedBox(height: 12),
            if (_processing)
              const Center(child: CircularProgressIndicator())
            else if (_decoded != null)
              SelectableText(
                _decoded!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
