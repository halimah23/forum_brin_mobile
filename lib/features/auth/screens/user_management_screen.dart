import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/user_service.dart';
import '../widgets/user_account_card.dart';
import '../widgets/user_form_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  final UserModel currentUser;

  const UserManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  UserRole? _selectedRoleFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await UserService.getUsers(
      query: _searchQuery,
      roleFilter: _selectedRoleFilter,
    );

    if (mounted) {
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateUser() async {
    final newUser = await UserFormDialog.show(context);
    if (newUser != null && mounted) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun "${newUser.name}" (${newUser.userRole.displayName}) berhasil dibuat.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _handleEditUser(UserModel user) async {
    final updatedUser = await UserFormDialog.show(context, userToEdit: user);
    if (updatedUser != null && mounted) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perubahan data "${updatedUser.name}" berhasil disimpan.'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    if (user.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tindakan ditolak: Anda tidak dapat menghapus akun Anda sendiri.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Konfirmasi Hapus Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus akun ini secara permanen dari Supabase?',
              style: AppTypography.bodySmall.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${user.email} • ${user.userRole.displayName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await UserService.deleteUser(
        userId: user.id!,
        currentSuperAdminId: widget.currentUser.id ?? '',
      );

      if (mounted) {
        if (success) {
          _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun "${user.name}" telah dihapus.'),
              backgroundColor: AppColors.slate800,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus akun pengguna.'),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Pengguna & Akses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.white),
            ),
            Text(
              'Total ${_allUsers.length} akun terdaftar di Supabase',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Tambah Akun Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: _handleCreateUser,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Panel Pencarian & Filter Peran
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  // Kolom Pencarian
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _loadUsers();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama, email, unit, atau jabatan...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.slate400),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate500),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadUsers();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips Per Role
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _roleChip(null, 'Semua Role'),
                        _roleChip(UserRole.member, 'Pegawai'),
                        _roleChip(UserRole.adminLksdm, 'Staf LKSDM'),
                        _roleChip(UserRole.adminPusat, 'Staf Pusat'),
                        _roleChip(UserRole.ketuaTim, 'Ketua Tim'),
                        _roleChip(UserRole.eksekutif, 'Eksekutif'),
                        _roleChip(UserRole.superAdmin, 'Super Admin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Daftar Pengguna
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.primaryRed,
                      child: _allUsers.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.45,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_search_rounded, size: 56, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tidak ada akun pengguna yang cocok.',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Ubah kata kunci pencarian atau reset filter role.',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _allUsers.length,
                              itemBuilder: (context, index) {
                                final user = _allUsers[index];
                                return UserAccountCard(
                                  user: user,
                                  currentAdminId: widget.currentUser.id ?? '',
                                  onEdit: () => _handleEditUser(user),
                                  onDelete: () => _handleDeleteUser(user),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(UserRole? role, String label) {
    final isSelected = _selectedRoleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primaryRed,
        backgroundColor: AppColors.slate100,
        side: BorderSide.none,
        onSelected: (_) {
          setState(() => _selectedRoleFilter = role);
          _loadUsers();
        },
      ),
    );
  }
}
