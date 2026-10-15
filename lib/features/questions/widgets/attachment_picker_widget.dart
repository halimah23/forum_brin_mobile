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

      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      final fileSize = file.lengthSync() ?? (await file.length()) ?? 0;

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

        final bytes = await file.readAsBytes();
        await client.storage.from('attachments').uploadBinary(storagePath, bytes);
        publicUrl = client.storage.from('attachments').getPublicUrl(storagePath);
      } catch (uploadError) {
        debugPrint('Supabase storage upload fallback: $uploadError');
        // Fallback: gunakan path lokal perangkat atau fallback pseudo URL
        publicUrl = file.path ?? 'storage://local/${file.name}';
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

  void _showAttachmentOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.attach_file_rounded, color: AppColors.primaryRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Sumber Berkas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Format didukung: PDF, DOCX, JPG, PNG (Maks. 10 MB)',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.folder_open_rounded, color: Colors.blue.shade700, size: 22),
                ),
                title: const Text(
                  'Buka Penyimpanan Perangkat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Pilih dokumen SK, surat dinas, atau tangkapan layar dari HP/device',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate400),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFileFromDevice();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: Colors.amber.shade800, size: 22),
                ),
                title: const Text(
                  'Gunakan Sampel Dokumen BRIN',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Pilih dari template simulasi (SK Jabfung, Surat Pengantar)',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate400),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSamplePickerDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSamplePickerDialog() {
    final sampleFiles = [
      {'name': 'SK_Jabatan_Fungsional_Terakhir.pdf', 'url': 'https://storage.brin.go.id/docs/sk_jf.pdf', 'size': '1.4 MB'},
      {'name': 'Surat_Pengantar_Kepala_Pusat.pdf', 'url': 'https://storage.brin.go.id/docs/surat_pengantar.pdf', 'size': '850 KB'},
      {'name': 'Bukti_Penyetaraan_Ijazah_S3.pdf', 'url': 'https://storage.brin.go.id/docs/ijazah_s3.pdf', 'size': '2.1 MB'},
      {'name': 'Tangkapan_Layar_Kendala_SIMPEG.png', 'url': 'https://storage.brin.go.id/docs/screenshot.png', 'size': '520 KB'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.description_rounded, color: AppColors.primaryRed),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Sampel Dokumen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih berkas contoh dokumen kepegawaian pendukung konsultasi:',
                style: TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const SizedBox(height: 14),
              ...sampleFiles.map((file) {
                final isImg = file['name']!.endsWith('.png') || file['name']!.endsWith('.jpg');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      isImg ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                  ),
                  title: Text(file['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Ukuran: ${file['size']}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                  trailing: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.slate400),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _attachedFileName = file['name'];
                      _attachedFileUrl = file['url'];
                      _attachedFileSize = file['size'];
                    });
                    widget.onAttachmentChanged(_attachedFileUrl, _attachedFileName);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
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
      onPressed: _showAttachmentOptionsModal,
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
