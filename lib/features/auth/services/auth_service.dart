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
          // Cari record di tabel users terlebih dahulu
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
          } catch (_) {}

          // Fallback ke tabel profiles
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
            email: user.email ?? cleanInput,
            role: rawRole,
            unit: profileData['unit']?.toString(),
            tim: profileData['tim']?.toString(),
            jabatan: profileData['jabatan']?.toString(),
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

    // 3. Fallback ke tabel `public.profiles` legacy jika database belum dimigrasikan
    try {
      var profile = await _client
          .from('profiles')
          .select()
          .ilike('email', cleanInput)
          .maybeSingle();

      if (profile == null && cleanInput.contains('superadmin')) {
        profile = await _client
            .from('profiles')
            .select()
            .or('email.ilike.%superadmin%,email.ilike.%super.admin%')
            .limit(1)
            .maybeSingle();
      }

      if (profile != null) {
        final profileData = Map<String, dynamic>.from(profile);
        final rawRole = profileData['role']?.toString() ?? 'member';

        final userModel = UserModel(
          id: profileData['id']?.toString(),
          name: profileData['name']?.toString() ??
              profileData['nama']?.toString() ??
              cleanInput.split('@').first,
          email: profileData['email']?.toString() ?? cleanInput,
          role: rawRole,
          unit: profileData['unit']?.toString(),
          tim: profileData['tim']?.toString(),
          jabatan: profileData['jabatan']?.toString(),
          token: 'supabase-token-${profileData['id']}',
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (dbError) {
      debugPrint('Notice query fallback profiles Supabase: $dbError');
    }

    throw Exception('Akun "$cleanInput" tidak terdaftar di database Supabase.');
  }

  /// Mengambil data user saat ini yang tersinkronisasi dengan Supabase
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;

      if (user != null) {
        try {
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
        } catch (_) {}

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
          token: session?.accessToken ?? 'supabase-token-${user.id}',
        );

        await SessionManager.saveUser(userModel);
        return userModel;
      }
    } catch (e) {
      debugPrint('Warning fetch profile from Supabase Auth: $e');
    }

    // Periksa sesi lokal dan sinkronkan dengan profil terbaru dari Supabase
    final localUser = await SessionManager.getUser();
    if (localUser != null && localUser.id != null) {
      // Prioritaskan tabel users
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

      // Fallback ke tabel profiles jika tabel users belum tersedia
      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', localUser.id!)
            .maybeSingle();

        if (profile != null) {
          final profileData = Map<String, dynamic>.from(profile);
          final updated = UserModel.fromJson(profileData, token: localUser.token);
          await SessionManager.saveUser(updated);
          return updated;
        }
      } catch (e) {
        debugPrint('Warning refresh profile from Supabase profiles: $e');
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
