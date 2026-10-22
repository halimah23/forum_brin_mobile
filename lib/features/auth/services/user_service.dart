import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class UserService {
  static SupabaseClient get _client => Supabase.instance.client;

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

  /// Mengambil seluruh data pengguna secara langsung dari tabel `public.users` (atau `profiles`) di Supabase
  static Future<List<UserModel>> getUsers({
    String? query,
    UserRole? roleFilter,
  }) async {
    List<UserModel> users = [];
    try {
      final response = await _client
          .from('users')
          .select('*, teams:id_tim(*)')
          .order('first_name', ascending: true);
      final rawList = List<Map<String, dynamic>>.from(response);
      users = rawList.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching users from Supabase: $e');
      return [];
    }

    // Filter berdasarkan Role jika ditentukan
    if (roleFilter != null) {
      users = users.where((u) => u.userRole == roleFilter).toList();
    }

    // Filter berdasarkan Search Query (Nama, Username, Email, Satuan Kerja, Tim, Jabatan)
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      users = users.where((u) {
        final nameMatch = u.name.toLowerCase().contains(q);
        final usernameMatch = (u.username ?? '').toLowerCase().contains(q);
        final emailMatch = u.email.toLowerCase().contains(q);
        final unitMatch = (u.unit ?? '').toLowerCase().contains(q);
        final timMatch = (u.tim ?? '').toLowerCase().contains(q);
        final jabatanMatch = (u.jabatan ?? '').toLowerCase().contains(q);
        return nameMatch || usernameMatch || emailMatch || unitMatch || timMatch || jabatanMatch;
      }).toList();
    }

    return users;
  }

  /// Menambahkan akun pengguna baru ke tabel `public.users` atau `public.profiles` di Supabase
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

    // 1. Coba daftarkan akun ke auth.users via Supabase Auth client terpisah jika tersedia
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
      debugPrint('Notice Supabase Auth signUp: $authError');
    }

    // 2. Simpan record pengguna ke tabel `users` atau fallback `profiles`
    final newUserData = {
      'id_user': assignedId,
      'first_name': cleanName,
      'username': cleanEmail.split('@').first,
      'email': cleanEmail,
      'role': dbRole,
      'satuan_kerja': cleanUnit,
      'jabatan': cleanJabatan,
    };

    try {
      await _client.from('users').upsert(newUserData);
      return UserModel.fromJson(newUserData);
    } catch (e) {
      debugPrint('Notice insert to users failed, trying profiles: $e');
      final legacyData = {
        'id': assignedId,
        'name': cleanName,
        'email': cleanEmail,
        'role': dbRole,
        'unit': cleanUnit,
        'tim': cleanTim,
        'jabatan': cleanJabatan,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').upsert(legacyData);
      return UserModel.fromJson(legacyData);
    }
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

    try {
      await _client.from('users').update({
        'first_name': cleanName,
        'role': dbRole,
        'satuan_kerja': cleanUnit,
        'jabatan': cleanJabatan,
      }).eq('id_user', id);
      return true;
    } catch (_) {
      final updateData = {
        'name': cleanName,
        'role': dbRole,
        'unit': cleanUnit,
        'tim': cleanTim,
        'jabatan': cleanJabatan,
      };
      await _client.from('profiles').update(updateData).eq('id', id);
      return true;
    }
  }

  /// Menghapus akun pengguna dari tabel `public.users` atau `public.profiles` di Supabase secara permanen
  static Future<bool> deleteUser({
    required String userId,
    required String currentSuperAdminId,
  }) async {
    // Safety Guard: Superadmin tidak boleh menghapus akunnya sendiri
    if (userId.trim() == currentSuperAdminId.trim()) {
      throw Exception('Tindakan ditolak: Anda tidak dapat menghapus akun Superadmin Anda sendiri.');
    }

    try {
      await _client.from('users').delete().eq('id_user', userId);
      return true;
    } catch (_) {
      await _client.from('profiles').delete().eq('id', userId);
      return true;
    }
  }
}
