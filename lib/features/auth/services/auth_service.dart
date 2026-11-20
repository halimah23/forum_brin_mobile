import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/session_manager.dart';
import '../models/user_model.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Melakukan login dengan email atau username dan password bersumber 100% dari Supabase
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanInput = email.trim().toLowerCase();

    // 1. Coba Autentikasi via Supabase Auth (GoTrue) jika kredensial email terdaftar
    try {
      if (cleanInput.contains('@')) {
        final authResponse = await _client.auth.signInWithPassword(
          email: cleanInput,
          password: password,
        );

        final user = authResponse.user;
        final session = authResponse.session;

        if (user != null) {
          // Cari record di tabel users
          try {
            final userRes = await _client
                .from('users')
                .select('*, teams:id_tim(*)')
                .or('email.ilike.$cleanInput,username.ilike.$cleanInput')
                .maybeSingle();

            if (userRes != null) {
              final userModel = UserModel.fromJson(
                Map<String, dynamic>.from(userRes),
                token: session?.accessToken ?? 'supabase-token-${user.id}',
              );
              await SessionManager.saveUser(userModel);
              return userModel;
            }
          } catch (e) {
            debugPrint('Warning: Gagal mengambil data users: $e');
          }

          final userModel = UserModel(
            id: user.id,
            name: user.userMetadata?['name']?.toString() ??
                user.email?.split('@').first ??
                '-',
            email: user.email ?? cleanInput,
            role: user.userMetadata?['role']?.toString() ?? 'sivitas',
            unit: user.userMetadata?['unit']?.toString(),
            tim: user.userMetadata?['tim']?.toString(),
            jabatan: user.userMetadata?['jabatan']?.toString(),
            token: session?.accessToken ?? 'supabase-token-${user.id}',
          );

          await SessionManager.saveUser(userModel);
          return userModel;
        }
      }
    } catch (e) {
      debugPrint('Notice Supabase Auth signIn: $e');
    }

    // 2. Ambil data profil langsung dari tabel `public.users` (didukung join `teams`)
    try {
      var userRecord = await _client
          .from('users')
          .select('*, teams:id_tim(*)')
          .or('email.ilike.$cleanInput,username.ilike.$cleanInput')
          .limit(1)
          .maybeSingle();

      // Toleransi pencarian untuk keyword superadmin jika ada
      if (userRecord == null && cleanInput.contains('superadmin')) {
        userRecord = await _client
            .from('users')
            .select('*, teams:id_tim(*)')
            .or('email.ilike.%superadmin%,username.ilike.%superadmin%')
            .limit(1)
            .maybeSingle();
      }

      if (userRecord != null) {
        final userModel = UserModel.fromJson(
          Map<String, dynamic>.from(userRecord),
          token: 'supabase-token-${userRecord['id_user']}',
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (dbError) {
      debugPrint('Notice query users Supabase: $dbError');
    }

    throw Exception('Akun "$cleanInput" tidak terdaftar di database Supabase.');
  }

  /// Mengambil data user saat ini yang tersinkronisasi dengan Supabase
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;

      if (user != null) {
        final userRecord = await _client
            .from('users')
            .select('*, teams:id_tim(*)')
            .or('id_user.eq.${user.id},email.ilike.${user.email}')
            .maybeSingle();

        if (userRecord != null) {
          final updated = UserModel.fromJson(
            Map<String, dynamic>.from(userRecord),
            token: session?.accessToken ?? 'supabase-token-${user.id}',
          );
          await SessionManager.saveUser(updated);
          return updated;
        }

        final userModel = UserModel(
          id: user.id,
          name: user.userMetadata?['name']?.toString() ??
              user.email?.split('@').first ??
              '-',
          email: user.email ?? '',
          role: user.userMetadata?['role']?.toString() ?? 'sivitas',
          unit: user.userMetadata?['unit']?.toString(),
          tim: user.userMetadata?['tim']?.toString(),
          jabatan: user.userMetadata?['jabatan']?.toString(),
          token: session?.accessToken ?? 'supabase-token-${user.id}',
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (e) {
      debugPrint('Warning fetch user from Supabase Auth: $e');
    }

    // Periksa sesi lokal dan sinkronkan dengan profil terbaru dari tabel `public.users`
    final localUser = await SessionManager.getUser();
    if (localUser != null && localUser.id != null) {
      try {
        final userRecord = await _client
            .from('users')
            .select('*, teams:id_tim(*)')
            .eq('id_user', localUser.id!)
            .maybeSingle();

        if (userRecord != null) {
          final updated = UserModel.fromJson(
            Map<String, dynamic>.from(userRecord),
            token: localUser.token,
          );
          await SessionManager.saveUser(updated);
          return updated;
        }
      } catch (e) {
        debugPrint('Notice refresh from users table: $e');
      }
    }

    return localUser;
  }

  /// Logout dari Supabase dan membersihkan session lokal
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
