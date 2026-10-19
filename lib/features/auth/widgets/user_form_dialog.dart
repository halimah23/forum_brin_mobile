import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../../questions/data/lksdm_catalog_data.dart';
import '../../questions/data/tusi_catalog_data.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/user_service.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? userToEdit;

  const UserFormDialog({
    super.key,
    this.userToEdit,
  });

  static Future<UserModel?> show(BuildContext context, {UserModel? userToEdit}) {
    return showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserFormDialog(userToEdit: userToEdit),
    );
  }

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _unitController;
  late TextEditingController _jabatanController;

  late UserRole _selectedRole;
  String? _selectedTimOrLksdm;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  bool get isEditMode => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;

    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _passwordController = TextEditingController(text: 'BRINpop2026!');
    _unitController = TextEditingController(text: u?.unit ?? 'BOSDM BRIN');
    _jabatanController = TextEditingController(text: u?.jabatan ?? 'Pegawai');

    _selectedRole = u?.userRole ?? UserRole.member;
    _selectedTimOrLksdm = u?.tim ?? (u?.lksdm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _unitController.dispose();
    _jabatanController.dispose();
    super.dispose();
  }

  List<String> _getTimOptions() {
    if (_selectedRole == UserRole.adminLksdm) {
      return LksdmCatalogData.allLksdm.map((l) => l.name).toList();
    } else if (_selectedRole == UserRole.adminPusat ||
        _selectedRole == UserRole.ketuaTim ||
        _selectedRole == UserRole.admin) {
      return TusiCatalogData.centralTeams;
    } else if (_selectedRole == UserRole.eksekutif) {
      return ['Manajemen & Eksekutif BRIN', 'Pimpinan BRIN'];
    } else if (_selectedRole == UserRole.superAdmin) {
      return ['Tim Administrator Platform', 'PUSDATIN BRIN'];
    }
    return [
      'Layanan Kawasan SDM 1 : Thamrin I',
      'Layanan Kawasan SDM 2 : Thamrin II',
      'Tim Mutasi & Kepangkatan',
      'Tim Kinerja & Karir',
      'Umum / Pelaksana',
    ];
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final selectedTim = _selectedTimOrLksdm ?? _getTimOptions().first;

      if (isEditMode) {
        final success = await UserService.updateUser(
          id: widget.userToEdit!.id!,
          name: _nameController.text.trim(),
          role: _selectedRole,
          unit: _unitController.text.trim(),
          tim: selectedTim,
          jabatan: _jabatanController.text.trim(),
        );

        if (!mounted) return;

        if (success) {
          final updated = widget.userToEdit!.copyWith(
            name: _nameController.text.trim(),
            role: _selectedRole.key,
            unit: _unitController.text.trim(),
            tim: selectedTim,
            jabatan: _jabatanController.text.trim(),
          );
          Navigator.pop(context, updated);
        } else {
          throw Exception('Gagal memperbarui data pengguna.');
        }
      } else {
        final newUser = await UserService.createUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          unit: _unitController.text.trim(),
          tim: selectedTim,
          jabatan: _jabatanController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pop(context, newUser);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timOptions = _getTimOptions();
    if (_selectedTimOrLksdm == null || !timOptions.contains(_selectedTimOrLksdm)) {
      _selectedTimOrLksdm = timOptions.isNotEmpty ? timOptions.first : null;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEditMode
                          ? const Color(0xFF0284C7).withAlpha(25)
                          : AppColors.primaryRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isEditMode ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                      color: isEditMode ? const Color(0xFF0284C7) : AppColors.primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode ? 'Edit Data Pengguna' : 'Tambah Akun Pengguna Baru',
                          style: AppTypography.heading2.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditMode
                              ? 'Perbarui metadata & hak akses pengguna'
                              : 'Akun akan terdaftar langsung di Supabase profiles',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.slate400),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              // Formulir Input
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Lengkap
                        _buildLabel('Nama Lengkap & Gelar *'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            hint: 'Contoh: Ahmad Syahputra, M.Si.',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama lengkap tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Alamat Email
                        _buildLabel('Alamat Email BRIN *'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: isEditMode, // Email dibuat tidak dapat diubah di edit mode
                          decoration: _inputDecoration(
                            hint: 'nama.pegawai@brin.go.id',
                            prefixIcon: Icons.alternate_email_rounded,
                            fillColor: isEditMode ? AppColors.slate100 : Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!val.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Awal (Hanya untuk tambah akun baru)
                        if (!isEditMode) ...[
                          _buildLabel('Password Awal Akun *'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              hint: 'Default: BRINpop2026!',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.slate500,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Password bawaan sistem disetel ke: BRINpop2026!',
                            style: TextStyle(fontSize: 10.5, color: AppColors.slate500, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Pilihan Peran / Role
                        _buildLabel('Peran / Hak Akses Pengguna *'),
                        DropdownButtonFormField<UserRole>(
                          initialValue: _selectedRole,
                          decoration: _inputDecoration(prefixIcon: Icons.badge_outlined),
                          items: const [
                            DropdownMenuItem(value: UserRole.member, child: Text('Pegawai (Member)')),
                            DropdownMenuItem(value: UserRole.adminLksdm, child: Text('Staf Admin LKSDM Kawasan')),
                            DropdownMenuItem(value: UserRole.adminPusat, child: Text('Staf Admin Layanan Pusat')),
                            DropdownMenuItem(value: UserRole.ketuaTim, child: Text('Ketua Tim Layanan SDM')),
                            DropdownMenuItem(value: UserRole.eksekutif, child: Text('Eksekutif / Pimpinan BRIN')),
                            DropdownMenuItem(value: UserRole.superAdmin, child: Text('Super Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRole = val;
                                final newOpts = _getTimOptions();
                                _selectedTimOrLksdm = newOpts.first;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Unit Kerja
                        _buildLabel('Unit Kerja Induk *'),
                        TextFormField(
                          controller: _unitController,
                          decoration: _inputDecoration(
                            hint: 'Contoh: BOSDM Pusat / Kawasan Thamrin / SETTAMA',
                            prefixIcon: Icons.business_outlined,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Unit kerja tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Tim Layanan / Kawasan LKSDM
                        _buildLabel(
                          _selectedRole == UserRole.adminLksdm
                              ? 'Wilayah Kawasan LKSDM *'
                              : 'Tim Layanan / Fungsi Kepegawaian *',
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTimOrLksdm,
                          isExpanded: true,
                          decoration: _inputDecoration(prefixIcon: Icons.groups_outlined),
                          items: timOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(
                                opt,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedTimOrLksdm = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Jabatan
                        _buildLabel('Jabatan / Posisi *'),
                        TextFormField(
                          controller: _jabatanController,
                          decoration: _inputDecoration(
                            hint: 'Contoh: Peneliti Ahli Muda / Analis SDM',
                            prefixIcon: Icons.work_outline_rounded,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Jabatan tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              // Tombol Aksi Batal & Simpan
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditMode ? const Color(0xFF0284C7) : AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(isEditMode ? 'Simpan Perubahan' : 'Buat Akun'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.slate800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.slate400),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.slate400) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
    );
  }
}
