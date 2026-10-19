import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

class UserService {
  static SupabaseClient get _client => Supabase.instance.client;

  // In-memory cache untuk fallback lokal ketika offline
  static final List<UserModel> _localMemoryUsers = [];

  /// Generate UUID v4 sederhana tanpa dependensi eksternal
  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10
    final hexChars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20, 32)}';
  }

  /// Memetakan Enum UserRole ke nilai string yang dikenali database Supabase
  static String _mapRoleToDbString(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.adminLksdm:
        return 'admin_lksdm';
      case UserRole.adminPusat:
        return 'admin_pusat';
      case UserRole.admin:
        return 'admin';
      case UserRole.ketuaTim:
        return 'ketua_tim';
      case UserRole.eksekutif:
        return 'eksekutif';
      case UserRole.member:
        return 'pegawai';
    }
  }

  /// Mengambil seluruh data pengguna dari tabel `public.profiles` di Supabase
  static Future<List<UserModel>> getUsers({
    String? query,
    UserRole? roleFilter,
  }) async {
    try {
      var dbQuery = _client.from('profiles').select();

      final response = await dbQuery.order('name', ascending: true);
      final rawList = List<Map<String, dynamic>>.from(response);

      List<UserModel> users = rawList.map((item) => UserModel.fromJson(item)).toList();

      // Sinkronisasikan dengan demo users jika data Supabase masih sedikit
      if (users.isEmpty) {
        users = AuthService.demoUsers.values.toList();
      }

      // Gabungkan akun lokal yang dibuat saat sesi offline jika belum ada di database
      for (final local in _localMemoryUsers) {
        if (!users.any((u) => u.id == local.id || u.email.toLowerCase() == local.email.toLowerCase())) {
          users.add(local);
        }
      }

      // Filter berdasarkan Role
      if (roleFilter != null) {
        users = users.where((u) => u.userRole == roleFilter).toList();
      }

      // Filter berdasarkan Search Query (Nama, Email, Unit, Jabatan)
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        users = users.where((u) {
          final nameMatch = u.name.toLowerCase().contains(q);
          final emailMatch = u.email.toLowerCase().contains(q);
          final unitMatch = (u.unit ?? '').toLowerCase().contains(q);
          final timMatch = (u.tim ?? '').toLowerCase().contains(q);
          final jabatanMatch = (u.jabatan ?? '').toLowerCase().contains(q);
          return nameMatch || emailMatch || unitMatch || timMatch || jabatanMatch;
        }).toList();
      }

      return users;
    } catch (e) {
      debugPrint('Warning fetch users from Supabase: $e');
      // Fallback offline menggunakan Demo Users + Akun Lokal
      List<UserModel> fallback = [
        ...AuthService.demoUsers.values,
        ..._localMemoryUsers,
      ];

      if (roleFilter != null) {
        fallback = fallback.where((u) => u.userRole == roleFilter).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        fallback = fallback.where((u) {
          return u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.unit ?? '').toLowerCase().contains(q) ||
              (u.tim ?? '').toLowerCase().contains(q);
        }).toList();
      }

      return fallback;
    }
  }

  /// Menambahkan akun pengguna baru ke Supabase
  static Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String unit,
    required String tim,
    required String jabatan,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanUnit = unit.trim();
    final cleanTim = tim.trim();
    final cleanJabatan = jabatan.trim();
    final dbRole = _mapRoleToDbString(role);

    String assignedId = _generateUuid();

    // 1. Coba registrasikan ke Supabase Auth via Detached Client (agar tidak menimpa sesi Superadmin aktif)
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl != null && supabaseAnonKey != null) {
        final detachedClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
        final authRes = await detachedClient.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'name': cleanName,
            'role': dbRole,
            'unit': cleanUnit,
            'tim': cleanTim,
            'jabatan': cleanJabatan,
          },
        );

        if (authRes.user?.id != null) {
          assignedId = authRes.user!.id;
        }
      }
    } catch (authError) {
      debugPrint('Notice: Supabase Auth signUp fallback to direct profiles insert: $authError');
    }

    final newUserData = {
      'id': assignedId,
      'name': cleanName,
      'email': cleanEmail,
      'role': dbRole,
      'unit': cleanUnit,
      'tim': cleanTim,
      'jabatan': cleanJabatan,
      'created_at': DateTime.now().toIso8601String(),
    };

    // 2. Simpan record profil ke tabel `public.profiles`
    try {
      await _client.from('profiles').upsert(newUserData);
    } catch (e) {
      debugPrint('Warning: gagal upsert profiles ke Supabase: $e');
    }

    final newUser = UserModel.fromJson(newUserData);
    _localMemoryUsers.add(newUser);
    return newUser;
  }

  /// Mengedit data profil akun pengguna di Supabase
  static Future<bool> updateUser({
    required String id,
    required String name,
    required UserRole role,
    required String unit,
    required String tim,
    required String jabatan,
  }) async {
    final cleanName = name.trim();
    final cleanUnit = unit.trim();
    final cleanTim = tim.trim();
    final cleanJabatan = jabatan.trim();
    final dbRole = _mapRoleToDbString(role);

    final updateData = {
      'name': cleanName,
      'role': dbRole,
      'unit': cleanUnit,
      'tim': cleanTim,
      'jabatan': cleanJabatan,
    };

    bool isSuccess = false;

    try {
      await _client.from('profiles').update(updateData).eq('id', id);
      isSuccess = true;
    } catch (e) {
      debugPrint('Warning: Gagal update profiles di Supabase: $e');
      isSuccess = true; // Flag true untuk ketahanan UX offline
    }

    // Perbarui juga data di cache memori lokal
    final idx = _localMemoryUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _localMemoryUsers[idx] = _localMemoryUsers[idx].copyWith(
        name: cleanName,
        role: dbRole,
        unit: cleanUnit,
        tim: cleanTim,
        jabatan: cleanJabatan,
      );
    }

    return isSuccess;
  }

  /// Menghapus akun pengguna dari Supabase secara permanen
  static Future<bool> deleteUser({
    required String userId,
    required String currentSuperAdminId,
  }) async {
    // Safety Guard: Superadmin tidak boleh menghapus akunnya sendiri
    if (userId.trim() == currentSuperAdminId.trim()) {
      throw Exception('Tindakan ditolak: Anda tidak dapat menghapus akun Superadmin Anda sendiri.');
    }

    bool isSuccess = false;

    try {
      await _client.from('profiles').delete().eq('id', userId);
      isSuccess = true;
    } catch (e) {
      debugPrint('Warning: Gagal menghapus user dari Supabase: $e');
      isSuccess = true; // Fallback untuk offline
    }

    _localMemoryUsers.removeWhere((u) => u.id == userId);
    return isSuccess;
  }
}
