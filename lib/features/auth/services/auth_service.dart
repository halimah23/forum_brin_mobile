import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/session_manager.dart';
import '../models/user_model.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Melakukan login dengan email dan password via Supabase Auth
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = authResponse.user;
      final session = authResponse.session;

      if (user == null) {
        throw Exception('Gagal melakukan autentikasi dengan Supabase.');
      }

      // Ambil detail profil user dari tabel `profiles`
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
        email: user.email ?? email,
        role: rawRole,
        unit: profileData['unit']?.toString(),
        tim: profileData['tim']?.toString(),
        jabatan: profileData['jabatan']?.toString(),
        token: session?.accessToken,
      );

      // Simpan kondisi sesi & profil ke SharedPreferences
      await SessionManager.saveUser(userModel);

      return userModel;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception('Email atau password yang Anda masukkan salah.');
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        throw Exception('Email belum dikonfirmasi. Silakan periksa inbox email Anda.');
      }
      throw Exception(e.message);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Koneksi internet bermasalah. Periksa jaringan Anda.');
      }
      rethrow;
    }
  }

  /// Mengambil data user saat ini (mencoba sesi Supabase dulu, fallback ke Shared Preferences)
  static Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;

    if (user != null) {
      try {
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

        // Update cache lokal
        await SessionManager.saveUser(userModel);
        return userModel;
      } catch (e) {
        debugPrint('Warning fetch profile: $e');
      }
    }

    // Fallback ke data lokal jika offline atau query gagal
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
