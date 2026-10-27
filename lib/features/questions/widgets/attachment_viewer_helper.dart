import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../screens/full_screen_image_viewer.dart';

class AttachmentViewerHelper {
  /// Memeriksa apakah URL atau nama berkas merupakan format gambar
  static bool isImageFile(String url, String? fileName) {
    final lowerUrl = url.toLowerCase().split('?').first;
    final lowerName = (fileName ?? '').toLowerCase();

    const imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.bmp',
    ];

    return imageExtensions.any((ext) =>
        lowerUrl.endsWith(ext) ||
        lowerName.endsWith(ext) ||
        lowerUrl.contains(ext));
  }

  /// Mendapatkan MIME type berkas berdasarkan ekstensi nama berkas
  static String getMimeType(String fileName) {
    final lower = fileName.toLowerCase().split('?').first;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }

  /// Memeriksa apakah path merupakan berkas lokal perangkat (bukan URL web publik)
  static bool isLocalPath(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return false;
    }
    return true;
  }

  /// Membuka atau menampilkan berkas lampiran tiket secara cerdas
  static Future<void> openAttachment(
    BuildContext context, {
    required String url,
    String? fileName,
  }) async {
    final effectiveName = fileName != null && fileName.isNotEmpty
        ? fileName
        : (url.split('/').last.split('?').first.isNotEmpty
            ? url.split('/').last.split('?').first
            : 'Berkas Lampiran');

    // 1. Jika berkas adalah Gambar -> Tampilkan di FullScreenImageViewer
    if (isImageFile(url, fileName)) {
      if (isLocalPath(url)) {
        final localFile = File(url);
        if (!localFile.existsSync()) {
          _showLocalMissingDialog(context, effectiveName, url);
          return;
        }
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(
            imageUrl: url,
            fileName: effectiveName,
          ),
        ),
      );
      return;
    }

    // 2. Jika berkas adalah Dokumen (PDF, Word, Excel, dsb.)
    await _openDocument(context, url, effectiveName);
  }

  /// Membuka berkas dokumen menggunakan browser / aplikasi pembaca eksternal
  static Future<void> _openDocument(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    // A. Kasus Berkas Lokal
    if (isLocalPath(url)) {
      final file = File(url);
      if (!file.existsSync()) {
        _showLocalMissingDialog(context, fileName, url);
        return;
      }

      final fileUri = Uri.file(url);
      try {
        final launched = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          if (context.mounted) {
            _showDocumentFallbackDialog(context, fileName, url, isLocal: true);
          }
        }
      } catch (e) {
        debugPrint('Error launching local document: $e');
        if (context.mounted) {
          _showDocumentFallbackDialog(context, fileName, url, isLocal: true);
        }
      }
      return;
    }

    // B. Kasus Berkas URL Cloud (HTTP/HTTPS)
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alamat URL berkas tidak valid.'),
            backgroundColor: AppColors.colorPrimary,
          ),
        );
      }
      return;
    }

    try {
      // Prioritaskan membuka dengan aplikasi bawaan perangkat (Adobe Reader, Office, Browser)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback ke in-app browser view jika external application gagal
        final inAppLaunched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );

        if (!inAppLaunched && context.mounted) {
          _showDocumentFallbackDialog(context, fileName, url, isLocal: false);
        }
      }
    } catch (e) {
      debugPrint('Error launching document URL: $e');
      if (context.mounted) {
        _showDocumentFallbackDialog(context, fileName, url, isLocal: false);
      }
    }
  }

  /// Dialog informasi jika berkas lokal belum terunggah ke Cloud Storage
  static void _showLocalMissingDialog(
    BuildContext context,
    String fileName,
    String rawPath,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berkas Belum Tersimpan di Cloud',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lampiran ini tercatat sebagai berkas cache lokal pada perangkat pengunggah dan tidak dapat diakses dari perangkat Anda.\n\nSilakan minta pengunggah untuk melampirkan ulang berkas ini melalui obrolan tiket.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.slate700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  /// Dialog cadangan untuk dokumen jika peluncur otomatis tidak didukung
  static void _showDocumentFallbackDialog(
    BuildContext context,
    String fileName,
    String url, {
    required bool isLocal,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.file_present_rounded, color: AppColors.colorPrimary, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Buka Dokumen Lampiran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi pembaca berkas default tidak merespons. Anda dapat membuka atau menyalin tautan berkas di bawah ini:',
              style: TextStyle(fontSize: 12, color: AppColors.slate700),
            ),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue),
            ),
          ],
        ),
        actions: [
          if (!isLocal) ...[
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Tautan'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan berhasil disalin ke clipboard')),
                );
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
              label: const Text('Buka di Browser'),
              onPressed: () async {
                Navigator.pop(ctx);
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        ],
      ),
    );
  }
}
