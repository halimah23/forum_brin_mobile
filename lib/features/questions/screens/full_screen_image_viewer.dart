import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Tutup',
        ),
        title: Text(
          fileName.isNotEmpty ? fileName : 'Pratinjau Gambar',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isNetwork)
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 22),
              tooltip: 'Buka di Browser',
              onPressed: () async {
                final uri = Uri.tryParse(imageUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka tautan browser')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImageContent(context),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final totalBytes = loadingProgress.expectedTotalBytes;
          final loadedBytes = loadingProgress.cumulativeBytesLoaded;
          final progress = totalBytes != null && totalBytes > 0
              ? loadedBytes / totalBytes
              : null;
          return Center(
            child: CircularProgressIndicator(
              value: progress,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(
          context,
          'Gagal memuat gambar dari server.\nPastikan koneksi internet stabil.',
        ),
      );
    }

    // Penanganan Berkas Lokal
    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(
          context,
          'Gagal memuat berkas gambar dari memori perangkat.',
        ),
      );
    }

    return _buildErrorWidget(
      context,
      'Berkas gambar tidak ditemukan di perangkat ini.\n(Berkas belum terunggah ke Cloud Storage)',
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Tutup'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
