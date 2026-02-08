import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _inputImage;
  File? _outputImage;
  bool _processing = false;
  int _threshold = 140;

  Future<void> _pickSource(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _inputImage = File(image.path);
        _outputImage = null;
      });
    }
  }

  Future<void> _process() async {
    if (_inputImage == null) return;
    setState(() => _processing = true);
    try {
      final bytes = await _inputImage!.readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) throw Exception('Falha ao abrir imagem');
      var image = img.copyResize(src, width: src.width, height: src.height);
      final out = img.Image(width: image.width, height: image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          final r = p.r.toInt();
          final g = p.g.toInt();
          final b = p.b.toInt();
          final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b).round();
          final v = luminance >= _threshold ? 255 : 0;
          out.setPixelRgba(x, y, v, v, v, 255);
        }
      }
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(img.encodePng(out));
      setState(() {
        _outputImage = file;
      });
    } catch (_) {}
    setState(() => _processing = false);
  }

  Future<void> _save() async {
    if (_outputImage == null) return;
    Directory? baseDir;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      baseDir = await getDownloadsDirectory();
    }
    baseDir ??= await getExternalStorageDirectory();
    baseDir ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir!.path}/Ferramentas/Scanner');
    if (!await dir.exists()) await dir.create(recursive: true);
    final dst = File('${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.png');
    await dst.writeAsBytes(await _outputImage!.readAsBytes());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Documento salvo em: ${dst.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Documentos')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickSource(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickSource(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_inputImage != null) ...[
            Text('Ajuste de Threshold: $_threshold'),
            Slider(
              value: _threshold.toDouble(),
              min: 60,
              max: 220,
              divisions: 160,
              onChanged: (v) => setState(() => _threshold = v.round()),
            ),
            ElevatedButton.icon(
              onPressed: _processing ? null : _process,
              icon: _processing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.tune),
              label: Text(_processing ? 'Processando...' : 'Processar'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: _inputImage != null ? Image.file(_inputImage!, fit: BoxFit.contain) : const SizedBox(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: _outputImage != null ? Image.file(_outputImage!, fit: BoxFit.contain) : const Center(child: Text('Resultado')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_outputImage != null)
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.download),
                label: const Text('Salvar'),
              ),
          ],
        ],
      ),
    );
  }
}
