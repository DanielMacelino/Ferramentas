import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GridCropScreen extends StatefulWidget {
  const GridCropScreen({super.key});

  @override
  State<GridCropScreen> createState() => _GridCropScreenState();
}

class _GridCropScreenState extends State<GridCropScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  int _rows = 3;
  int _columns = 3;
  List<File> _croppedImages = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _croppedImages = [];
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _croppedImages = [];
    });

    try {
      // 1. Decode image
      final bytes = await _selectedImage!.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception("Não foi possível decodificar a imagem.");
      }

      // 2. Calculate dimensions
      final width = originalImage.width;
      final height = originalImage.height;
      final pieceWidth = (width / _columns).floor();
      final pieceHeight = (height / _rows).floor();

      final tempDir = await getTemporaryDirectory();
      final List<File> generatedFiles = [];

      // 3. Crop loop
      for (int y = 0; y < _rows; y++) {
        for (int x = 0; x < _columns; x++) {
          final cropped = img.copyCrop(
            originalImage,
            x: x * pieceWidth,
            y: y * pieceHeight,
            width: pieceWidth,
            height: pieceHeight,
          );

          // 4. Save to temp file
          final fileName = 'grid_${y}_$x.jpg';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(img.encodeJpg(cropped));
          generatedFiles.add(file);
        }
      }

      if (mounted) {
        setState(() {
          _croppedImages = generatedFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _exportImages() async {
    if (_croppedImages.isEmpty) return;
    
    final xFiles = _croppedImages.map((file) => XFile(file.path)).toList();
    await Share.shareXFiles(xFiles, text: 'Imagens cortadas pelo Ferramentas App');
  }

  Future<void> _saveImages() async {
    if (_croppedImages.isEmpty) return;
    try {
      Directory? baseDir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        baseDir = await getDownloadsDirectory();
      }
      baseDir ??= await getExternalStorageDirectory();
      baseDir ??= await getApplicationDocumentsDirectory();

      final dir = Directory('${baseDir!.path}/Ferramentas/GridCrop/${DateTime.now().millisecondsSinceEpoch}');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      for (int i = 0; i < _croppedImages.length; i++) {
        final src = _croppedImages[i];
        final dst = File('${dir.path}/parte_${i + 1}.jpg');
        await dst.writeAsBytes(await src.readAsBytes());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagens salvas em: ${dir.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao salvar imagens: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cortar em Grid'),
        actions: [
          if (_croppedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportImages,
            ),
          if (_croppedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveImages,
              tooltip: 'Salvar imagens',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    style: BorderStyle.solid,
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
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque para selecionar imagem',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Linhas (Horizontal)'),
                      Slider(
                        value: _rows.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _rows.toString(),
                        onChanged: (value) {
                          setState(() {
                            _rows = value.toInt();
                            _croppedImages = []; // Reset preview
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Colunas (Vertical)'),
                      Slider(
                        value: _columns.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _columns.toString(),
                        onChanged: (value) {
                          setState(() {
                            _columns = value.toInt();
                            _croppedImages = []; // Reset preview
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _selectedImage == null || _isProcessing ? null : _processImage,
              icon: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cut),
              label: Text(_isProcessing ? 'Processando...' : 'Cortar Imagem'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Results Preview
            if (_croppedImages.isNotEmpty) ...[
              const Text(
                'Pré-visualização:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _croppedImages.length,
                itemBuilder: (context, index) {
                  return Image.file(
                    _croppedImages[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
