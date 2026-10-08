import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/session_manager.dart';
import '../models/user_model.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Daftar Akun Demo Resmi untuk 5 Role Pengguna
  static final Map<String, UserModel> demoUsers = {
    'pegawai@brin.go.id': const UserModel(
      id: '77777777-7777-7777-7777-777777777777',
      name: 'Ahmad Syahputra, M.Si.',
      email: 'pegawai@brin.go.id',
      role: 'member',
      unit: 'SETTAMA',
      tim: 'Layanan Kawasan SDM 1 : Thamrin I',
      jabatan: 'Peneliti Ahli Muda',
      token: 'demo-token-member',
    ),
    'admin.lksdm1@brin.go.id': const UserModel(
      id: '44444444-4444-4444-4444-444444444444',
      name: 'Budi Handoko, S.Kom.',
      email: 'admin.lksdm1@brin.go.id',
      role: 'admin',
      unit: 'LKSDM 1',
      tim: 'Layanan Kawasan SDM 1 : Thamrin I',
      jabatan: 'Staf Admin LKSDM Kawasan',
      token: 'demo-token-admin-lksdm',
    ),
    'admin.pusat@brin.go.id': const UserModel(
      id: '55555555-5555-5555-5555-555555555555',
      name: 'Rina Melati, S.AP.',
      email: 'admin.pusat@brin.go.id',
      role: 'admin',
      unit: 'BOSDM Pusat',
      tim: 'Fungsi Pengelolaan data dan informasi SDM',
      jabatan: 'Staf Admin Layanan SDM Pusat',
      token: 'demo-token-admin-pusat',
    ),
    'ketuatim@brin.go.id': const UserModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'Dr. Irwan Setiawan, M.Sc.',
      email: 'ketuatim@brin.go.id',
      role: 'ketua_tim',
      unit: 'BOSDM Pusat',
      tim: 'Tim Mutasi & Kepangkatan',
      jabatan: 'Ketua Tim Mutasi & Kepangkatan',
      token: 'demo-token-ketuatim',
    ),
    'eksekutif@brin.go.id': const UserModel(
      id: '66666666-6666-6666-6666-666666666666',
      name: 'Prof. Dr. Hendra Wijaya',
      email: 'eksekutif@brin.go.id',
      role: 'eksekutif',
      unit: 'BOSDM',
      tim: 'Manajemen & Eksekutif BRIN',
      jabatan: 'Kepala Biro Organisasi dan SDM',
      token: 'demo-token-eksekutif',
    ),
    'superadmin@brin.go.id': const UserModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Administrator Utama',
      email: 'superadmin@brin.go.id',
      role: 'super_admin',
      unit: 'PUSDATIN BRIN',
      tim: 'Tim Administrator Platform',
      jabatan: 'Super Admin System',
      token: 'demo-token-superadmin',
    ),
  };

  /// Melakukan login dengan email dan password via Supabase Auth (dengan Mock Demo Fallback)
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Coba Autentikasi via Supabase Auth jika tersedia
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = authResponse.user;
      final session = authResponse.session;

      if (user != null) {
        Map<String, dynamic> profileData = {};
        try {
          final profile = await _client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            profileData = Map<String, dynamic>.from(profile);
          }
        } catch (e) {
          debugPrint('Warning: Gagal mengambil data profiles: $e');
        }

        final rawRole = profileData['role']?.toString() ??
            user.userMetadata?['role']?.toString() ??
            'member';

        final userModel = UserModel(
          id: user.id,
          name: profileData['name']?.toString() ??
              profileData['nama']?.toString() ??
              user.userMetadata?['name']?.toString() ??
              user.email?.split('@').first ??
              '-',
          email: user.email ?? cleanEmail,
          role: rawRole,
          unit: profileData['unit']?.toString(),
          tim: profileData['tim']?.toString(),
          jabatan: profileData['jabatan']?.toString(),
          token: session?.accessToken,
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (e) {
      debugPrint('Supabase Auth error/offline: $e');
      // Jika akun merupakan salah satu demo user, gunakan fallback demo user model
      if (demoUsers.containsKey(cleanEmail)) {
        final demoModel = demoUsers[cleanEmail]!;
        await SessionManager.saveUser(demoModel);
        return demoModel;
      }
      if (e is AuthException) {
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          throw Exception('Email atau password yang Anda masukkan salah.');
        }
        throw Exception(e.message);
      }
    }

    // 2. Fallback untuk Demo Account jika Supabase belum terisi
    if (demoUsers.containsKey(cleanEmail)) {
      final demoModel = demoUsers[cleanEmail]!;
      await SessionManager.saveUser(demoModel);
      return demoModel;
    }

    throw Exception('Email atau password yang Anda masukkan tidak terdaftar.');
  }

  /// Mengambil data user saat ini (Supabase / SharedPreferences fallback)
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;

      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        final profileData =
            profile != null ? Map<String, dynamic>.from(profile) : <String, dynamic>{};

        final rawRole = profileData['role']?.toString() ??
            user.userMetadata?['role']?.toString() ??
            'member';

        final userModel = UserModel(
          id: user.id,
          name: profileData['name']?.toString() ??
              profileData['nama']?.toString() ??
              user.userMetadata?['name']?.toString() ??
              user.email?.split('@').first ??
              '-',
          email: user.email ?? '',
          role: rawRole,
          unit: profileData['unit']?.toString(),
          tim: profileData['tim']?.toString(),
          jabatan: profileData['jabatan']?.toString(),
          token: session?.accessToken,
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (e) {
      debugPrint('Warning fetch profile: $e');
    }

    return await SessionManager.getUser();
  }

  /// Logout dari Supabase dan membersihkan session lokal SharedPreferences
  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Warning saat signOut Supabase: $e');
    } finally {
      await SessionManager.clearSession();
    }
  }
}
