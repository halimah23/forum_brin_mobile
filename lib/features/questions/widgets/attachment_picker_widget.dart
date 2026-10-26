import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class AttachmentPickerWidget extends StatefulWidget {
  final Function(String? url, String? name) onAttachmentChanged;

  const AttachmentPickerWidget({
    super.key,
    required this.onAttachmentChanged,
  });

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  String? _attachedFileName;
  String? _attachedFileUrl;
  String? _attachedFileSize;
  bool _isUploading = false;

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  Future<void> _pickFileFromDevice() async {
    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      final file = result.files.first;
      final fileSize = file.size;

      // Batasan ukuran maksimum 10 MB
      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran berkas melebihi batas maksimal 10 MB.'),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        }
        return;
      }

      String? publicUrl;

      // Coba upload ke Supabase Storage (bucket 'attachments')
      try {
        final client = Supabase.instance.client;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storagePath = 'questions/${timestamp}_$safeName';

        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
        if (bytes != null) {
          await client.storage.from('attachments').uploadBinary(storagePath, bytes);
          publicUrl = client.storage.from('attachments').getPublicUrl(storagePath);
        } else {
          publicUrl = file.path ?? 'storage://local/${file.name}';
        }
      } catch (uploadError) {
        debugPrint('Supabase storage upload error: $uploadError');
        // Fallback: gunakan path lokal perangkat atau fallback pseudo URL
        publicUrl = file.path ?? 'storage://local/${file.name}';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catatan: Berkas disimpan sementara secara lokal karena unggahan Cloud gagal ($uploadError).'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _attachedFileName = file.name;
          _attachedFileUrl = publicUrl ?? file.name;
          _attachedFileSize = _formatFileSize(fileSize);
          _isUploading = false;
        });

        widget.onAttachmentChanged(_attachedFileUrl, _attachedFileName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berkas "${file.name}" berhasil dilampirkan.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih berkas: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
      _attachedFileUrl = null;
      _attachedFileSize = null;
    });
    widget.onAttachmentChanged(null, null);
  }

  IconData _getFileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return Icons.image_rounded;
    } else if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRed),
            ),
            SizedBox(width: 12),
            Text(
              'Sedang memproses berkas lampiran...',
              style: TextStyle(fontSize: 12.5, color: AppColors.slate700),
            ),
          ],
        ),
      );
    }

    if (_attachedFileName != null) {
      final isImage = _attachedFileName!.toLowerCase().endsWith('.png') ||
          _attachedFileName!.toLowerCase().endsWith('.jpg') ||
          _attachedFileName!.toLowerCase().endsWith('.jpeg');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isImage ? Colors.blue.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _getFileIcon(_attachedFileName!),
                size: 20,
                color: isImage ? Colors.blue.shade800 : AppColors.primaryRed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _attachedFileName!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Berkas siap dilampirkan',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF3B82F6)),
                      ),
                      if (_attachedFileSize != null) ...[
                        const Text(' • ', style: TextStyle(color: Color(0xFF93C5FD))),
                        Text(
                          _attachedFileSize!,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1E40AF)),
              onPressed: _removeAttachment,
              tooltip: 'Hapus Lampiran',
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _pickFileFromDevice,
      icon: const Icon(Icons.attach_file_rounded, size: 18),
      label: const Text('Lampirkan Berkas Bukti (PDF / Foto)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate700,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
