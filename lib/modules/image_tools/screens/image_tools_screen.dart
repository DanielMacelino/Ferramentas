import 'package:flutter/material.dart';
import 'package:ferramentas/modules/image_tools/screens/grid_crop_screen.dart';
import 'package:ferramentas/modules/image_tools/screens/ocr_screen.dart';
import 'package:ferramentas/modules/image_tools/screens/bg_remover_screen.dart';
import 'package:ferramentas/modules/image_tools/screens/document_scanner_screen.dart';
import 'package:ferramentas/modules/image_tools/screens/qr_reader_screen.dart';

class ImageToolsScreen extends StatelessWidget {
  const ImageToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferramentas de Imagem'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildToolCard(
            context,
            title: 'Cortar em Grid',
            description: 'Divida imagens em múltiplas partes para Instagram, etc.',
            icon: Icons.grid_on,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GridCropScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Scanner de Texto (OCR)',
            description: 'Extraia texto de imagens automaticamente.',
            icon: Icons.text_fields,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OCRScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Remover Fundo',
            description: 'Remova o fundo de imagens com um clique.',
            icon: Icons.image_not_supported,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BgRemoverScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Scanner de Documentos',
            description: 'Digitalize documentos com alto contraste.',
            icon: Icons.document_scanner,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Leitor de QR Code',
            description: 'Decodifique QR a partir de imagens.',
            icon: Icons.qr_code,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrReaderScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
