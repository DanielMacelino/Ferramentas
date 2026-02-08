import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class BgRemoverScreen extends StatefulWidget {
  const BgRemoverScreen({super.key});

  @override
  State<BgRemoverScreen> createState() => _BgRemoverScreenState();
}

class _BgRemoverScreenState extends State<BgRemoverScreen> {
  File? _selectedImage;
  File? _processedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _processedImage = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) {
        throw Exception('Falha ao decodificar a imagem');
      }
      var image = img.copyResize(src, width: src.width, height: src.height);

      // Amostrar a cor de fundo nas bordas para estimar o background
      int sampleCount = 0;
      int rSum = 0, gSum = 0, bSum = 0;
      int stepX = (image.width / 20).round();
      if (stepX < 1) stepX = 1;
      for (int x = 0; x < image.width; x += stepX) {
        final top = image.getPixel(x, 0);
        final bottom = image.getPixel(x, image.height - 1);
        rSum += top.r.toInt() + bottom.r.toInt();
        gSum += top.g.toInt() + bottom.g.toInt();
        bSum += top.b.toInt() + bottom.b.toInt();
        sampleCount += 2;
      }
      int stepY = (image.height / 20).round();
      if (stepY < 1) stepY = 1;
      for (int y = 0; y < image.height; y += stepY) {
        final left = image.getPixel(0, y);
        final right = image.getPixel(image.width - 1, y);
        rSum += left.r.toInt() + right.r.toInt();
        gSum += left.g.toInt() + right.g.toInt();
        bSum += left.b.toInt() + right.b.toInt();
        sampleCount += 2;
      }
      final bgR = (rSum / sampleCount).round();
      final bgG = (gSum / sampleCount).round();
      final bgB = (bSum / sampleCount).round();

      // Threshold de similaridade (ajustável)
      const threshold = 35; // funciona bem para fundos relativamente uniformes

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          final r = p.r.toInt();
          final g = p.g.toInt();
          final b = p.b.toInt();
          final dist = ((r - bgR).abs() + (g - bgG).abs() + (b - bgB).abs()) / 3;
          if (dist < threshold) {
            image.setPixelRgba(x, y, r, g, b, 0); // transparente
          } else {
            image.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }

      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
      await outFile.writeAsBytes(img.encodePng(image));
      if (mounted) {
        setState(() {
          _processedImage = outFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na remoção de fundo: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remover Fundo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
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
                            Icons.layers_clear,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecionar imagem para remover fundo',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _selectedImage == null || _isProcessing ? null : _processImage,
              icon: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high),
              label: Text(_isProcessing ? 'Removendo Fundo...' : 'Remover Fundo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            if (_processedImage != null) ...[
              const Text(
                'Resultado (Preview):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _processedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_processedImage == null) return;
                  try {
                    Directory? baseDir;
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                      baseDir = await getDownloadsDirectory();
                    }
                    baseDir ??= await getExternalStorageDirectory();
                    baseDir ??= await getApplicationDocumentsDirectory();
                    final dir = Directory('${baseDir!.path}/Ferramentas/RemoverFundo');
                    if (!await dir.exists()) await dir.create(recursive: true);
                    final dst = File('${dir.path}/removido_${DateTime.now().millisecondsSinceEpoch}.png');
                    await dst.writeAsBytes(await _processedImage!.readAsBytes());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PNG salvo em: ${dst.path}')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Falha ao salvar PNG: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Salvar PNG'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
