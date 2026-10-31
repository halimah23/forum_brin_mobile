import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../questions/data/lksdm_catalog_data.dart';
import '../../questions/widgets/attachment_viewer_helper.dart';
import '../services/broadcast_service.dart';

class CreateBroadcastScreen extends StatefulWidget {
  final UserModel currentUser;

  const CreateBroadcastScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateBroadcastScreen> createState() => _CreateBroadcastScreenState();
}

class _CreateBroadcastScreenState extends State<CreateBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late String _lksdmScope;
  bool _isUrgent = false;

  // Target Selection
  String _targetType = 'all_lksdm'; // 'all_lksdm', 'unit_filter', 'custom_users'
  String? _selectedUnit;
  List<UserModel> _eligibleUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoadingEligible = true;

  // Berkas Lampiran
  String? _attachmentName;
  String? _attachmentUrl;
  String? _attachmentSize;
  bool _isUploadingFile = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lksdmScope = widget.currentUser.isSuperAdmin
        ? 'ALL'
        : widget.currentUser.effectiveLksdm;
    _loadEligibleUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadEligibleUsers() async {
    setState(() => _isLoadingEligible = true);
    final users = await BroadcastService.getEligibleRecipients(
      lksdmScope: _lksdmScope,
    );
    if (mounted) {
      setState(() {
        _eligibleUsers = users;
        _isLoadingEligible = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploadingFile = false);
        return;
      }

      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          setState(() => _isUploadingFile = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran berkas melebihi batas maksimal 10 MB.'),
              backgroundColor: AppColors.colorPrimary,
            ),
          );
        }
        return;
      }

      // Unggah ke Supabase Storage (bucket 'attachments')
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = 'broadcasts/${timestamp}_$safeName';

      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) {
        throw Exception('Gagal membaca data berkas');
      }

      final mimeType = AttachmentViewerHelper.getMimeType(file.name);
      await client.storage.from('attachments').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      final publicUrl =
          client.storage.from('attachments').getPublicUrl(storagePath);

      if (mounted) {
        setState(() {
          _attachmentName = file.name;
          _attachmentUrl = publicUrl;
          _attachmentSize = _formatFileSize(file.size);
          _isUploadingFile = false;
        });
      }
    } catch (e) {
      debugPrint('Upload broadcast attachment error: $e');
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah berkas: $e'),
            backgroundColor: AppColors.colorPrimary,
          ),
        );
      }
    }
  }

  void _openManualUserSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _eligibleUsers.where((u) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return u.name.toLowerCase().contains(q) ||
                  (u.unit ?? '').toLowerCase().contains(q) ||
                  (u.username ?? '').toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Pegawai Penerima (${_selectedUserIds.length})',
                        style: AppTypography.heading3,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (_selectedUserIds.length ==
                                _eligibleUsers.length) {
                              _selectedUserIds.clear();
                            } else {
                              _selectedUserIds.addAll(
                                _eligibleUsers
                                    .map((u) => u.id ?? '')
                                    .where((id) => id.isNotEmpty),
                              );
                            }
                          });
                          setState(() {});
                        },
                        child: Text(
                          _selectedUserIds.length == _eligibleUsers.length
                              ? 'Batal Semua'
                              : 'Pilih Semua',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama, nip/username, atau unit...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setModalState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Pegawai tidak ditemukan'),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final u = filtered[idx];
                              final isSelected =
                                  _selectedUserIds.contains(u.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(
                                  u.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${u.unit ?? 'Unit tidak diketahui'} • ${u.effectiveLksdm}',
                                  style: AppTypography.bodySmall,
                                ),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true && u.id != null) {
                                      _selectedUserIds.add(u.id!);
                                    } else if (u.id != null) {
                                      _selectedUserIds.remove(u.id);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Selesai (${_selectedUserIds.length} Dipilih)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPreviewDialog() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _isUrgent ? Icons.warning_rounded : Icons.campaign_rounded,
              color: _isUrgent ? Colors.red : AppColors.colorPrimary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Pratinjau Broadcast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    '🚨 SIARAN PENTING / URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Text(
                _titleController.text.trim(),
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 4),
              Text(
                'Pengirim: ${widget.currentUser.name} (${widget.currentUser.role ?? 'LKSDM'}) • $_lksdmScope',
                style: AppTypography.caption,
              ),
              const Divider(height: 24),
              Text(
                _contentController.text.trim(),
                style: AppTypography.bodyMedium,
              ),
              if (_attachmentName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _attachmentName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _attachmentSize ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.colorPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _submitBroadcast();
            },
            child: const Text(
              'Kirim Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetType == 'custom_users' && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal 1 pegawai penerima.'),
          backgroundColor: AppColors.colorPrimary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final broadcast = await BroadcastService.createBroadcast(
        sender: widget.currentUser,
        lksdmScope: _lksdmScope,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _isUrgent ? 'urgent' : 'normal',
        targetType: _targetType,
        targetFilterValue: _targetType == 'unit_filter' ? _selectedUnit : null,
        selectedUserIds: _targetType == 'custom_users'
            ? _selectedUserIds.toList()
            : null,
        attachmentUrl: _attachmentUrl,
        attachmentName: _attachmentName,
        attachmentSize: _attachmentSize,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (broadcast != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Broadcast berhasil disiarkan ke ${broadcast.totalRecipients ?? 0} pegawai!',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Gagal mengirim broadcast');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.colorPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List unit/coverage dari katalog untuk LKSDM terkait
    final coverageUnits = LksdmCatalogData.allLksdm
        .where((l) =>
            _lksdmScope == 'ALL' ||
            l.shortName.toUpperCase() == _lksdmScope.toUpperCase())
        .expand((l) => l.coverageUnits)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Siaran / Broadcast LKSDM'),
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Pratinjau',
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: _showPreviewDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Info LKSDM Pengirim
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.colorPrimary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined,
                        color: AppColors.colorPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wilayah Siaran: $_lksdmScope (${_eligibleUsers.length} Pegawai Terdata)',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Switch Siaran Urgent
              Container(
                decoration: BoxDecoration(
                  color: _isUrgent ? Colors.red.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isUrgent ? Colors.red.shade400 : Colors.grey.shade300,
                  ),
                ),
                child: SwitchListTile(
                  title: Row(
                    children: [
                      Icon(
                        _isUrgent
                            ? Icons.warning_rounded
                            : Icons.notifications_active_outlined,
                        color: _isUrgent ? Colors.red : Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tandai sebagai Siaran Penting (Urgent)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isUrgent ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Pesan penting akan memunculkan pop-up peringatan otomatis di Beranda aplikasi pegawai.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isUrgent,
                  activeColor: Colors.red,
                  onChanged: (val) => setState(() => _isUrgent = val),
                ),
              ),

              const SizedBox(height: 16),

              // Judul Pengumuman
              Text('Judul Broadcast', style: AppTypography.heading4),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Edaran Pemutakhiran Data Pegawai LKSDM',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul broadcast tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Isi Pesan
              Text('Isi Pesan Siaran', style: AppTypography.heading4),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tuliskan pesan lengkap atau instruksi kepegawaian...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Isi pesan siaran tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Penargetan Penerima (Targeting Mode)
              Text('Target Penerima Siaran', style: AppTypography.heading4),
              const SizedBox(height: 8),

              // Opsi 1: Semua Pegawai LKSDM
              RadioListTile<String>(
                value: 'all_lksdm',
                groupValue: _targetType,
                title: Text(
                  'Semua Pegawai di $_lksdmScope',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Siarkan ke seluruh ${_eligibleUsers.length} pegawai dalam naungan wilayah ini',
                  style: const TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _targetType = val!),
              ),

              // Opsi 2: Berdasarkan Unit / Kawasan
              RadioListTile<String>(
                value: 'unit_filter',
                groupValue: _targetType,
                title: const Text(
                  'Berdasarkan Satuan Kerja / Kawasan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Kirim ke kelompok unit kerja tertentu di bawah LKSDM',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _targetType = val!),
              ),

              if (_targetType == 'unit_filter')
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      hintText: 'Pilih Satuan Kerja / Kawasan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: coverageUnits.map((u) {
                      return DropdownMenuItem<String>(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val),
                    validator: (val) {
                      if (_targetType == 'unit_filter' &&
                          (val == null || val.isEmpty)) {
                        return 'Silakan pilih satuan kerja target';
                      }
                      return null;
                    },
                  ),
                ),

              // Opsi 3: Pilih Manual Pegawai Tertentu
              RadioListTile<String>(
                value: 'custom_users',
                groupValue: _targetType,
                title: const Text(
                  'Pilih Manual Pegawai Tertentu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _selectedUserIds.isEmpty
                      ? 'Pilih satu atau beberapa pegawai spesifik'
                      : '${_selectedUserIds.length} Pegawai Dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedUserIds.isNotEmpty
                        ? AppColors.colorPrimary
                        : Colors.grey.shade700,
                    fontWeight: _selectedUserIds.isNotEmpty
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _targetType = val!);
                  _openManualUserSelector();
                },
              ),

              if (_targetType == 'custom_users')
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.people_outline, size: 18),
                    label: Text(
                      _selectedUserIds.isEmpty
                          ? 'Buka Daftar Pegawai'
                          : 'Ubah Pilihan (${_selectedUserIds.length} Dipilih)',
                    ),
                    onPressed: _openManualUserSelector,
                  ),
                ),

              const SizedBox(height: 20),

              // Berkas Lampiran
              Text('Lampiran Berkas (Opsional)', style: AppTypography.heading4),
              const SizedBox(height: 6),
              const Text(
                'Mendukung PDF, Word (DOC/DOCX), dan Gambar (JPG/PNG) hingga 10 MB.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              if (_isUploadingFile)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Mengunggah berkas ke Cloud Storage...'),
                    ],
                  ),
                )
              else if (_attachmentName != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          color: AppColors.colorPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachmentName!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _attachmentSize ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus Berkas',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _attachmentName = null;
                            _attachmentUrl = null;
                            _attachmentSize = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pilih Berkas Lampiran'),
                  onPressed: _pickFile,
                ),

              const SizedBox(height: 32),

              // Tombol Kirim Siaran
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _showPreviewDialog,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Siarkan Pengumuman Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
