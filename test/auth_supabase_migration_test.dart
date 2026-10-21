import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_brin_mobile/features/auth/models/user_role.dart';
import 'package:forum_brin_mobile/features/auth/services/auth_service.dart';
import 'package:forum_brin_mobile/features/auth/services/user_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = _RealHttpOverrides();

    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    await Supabase.initialize(url: url, publishableKey: key);
  });

  group('Supabase Direct Migration Tests (Auth & Users SOP Instansi)', () {
    test('UserService.getUsers fetches real users from Supabase users table', () async {
      final users = await UserService.getUsers();
      expect(users, isNotEmpty);
      expect(users.length, greaterThanOrEqualTo(200));

      // 1. Super Admin
      final aisyah = users.firstWhere((u) => u.username == 'aisy004' || u.email.contains('aisyah.febrianti'));
      expect(aisyah.name, contains('Aisyah Febrianti'));
      expect(aisyah.userRole, UserRole.superAdmin);

      // 2. Eksekutif
      final siti = users.firstWhere((u) => u.username == 'siti127' || u.email.contains('siti.halimah'));
      expect(siti.name, contains('Siti Halimah'));
      expect(siti.userRole, UserRole.eksekutif);

      // 3. Ketua Tim Pusat
      final fathur = users.firstWhere((u) => u.username == 'fath014' || u.email.contains('fathurrahman.adam'));
      expect(fathur.name, contains('Fathurrahman'));
      expect(fathur.userRole, UserRole.ketuaTim);

      // 4. Admin LKSDM
      final maria = users.firstWhere((u) => u.username == 'mari063' || u.email.contains('maria.fernanda'));
      expect(maria.name, contains('Maria Fernanda'));
      expect(maria.userRole, UserRole.adminLksdm);

      // 5. Pegawai / Member
      final manda = users.firstWhere((u) => u.username == 'mand001' || u.email.contains('manda.talita'));
      expect(manda.name, contains('Manda Talita'));
      expect(manda.userRole, UserRole.member);

      // Verify no legacy manual users exist
      final hasLegacyAhmad = users.any((u) => u.name == 'Ahmad Syahputra, M.Si.');
      expect(hasLegacyAhmad, isFalse, reason: 'Manual coding user Ahmad Syahputra must not exist');

      final hasLegacyBudi = users.any((u) => u.email == 'budi.pegawai@brin.go.id');
      expect(hasLegacyBudi, isFalse, reason: 'Old dummy user budi.pegawai must not exist');
    });

    test('AuthService.login authenticates Fathurrahman Adam Rahadian via email or username', () async {
      // Login via email
      final userByEmail = await AuthService.login(
        email: 'fathurrahman.adam.rahadian@brin.go.id',
        password: 'Password123!',
      );
      expect(userByEmail.name, contains('Fathurrahman'));
      expect(userByEmail.userRole, UserRole.ketuaTim);
      expect(userByEmail.id, isNotNull);

      // Login via username
      final userByUsername = await AuthService.login(
        email: 'fath014',
        password: 'Password123!',
      );
      expect(userByUsername.name, contains('Fathurrahman'));
      expect(userByUsername.userRole, UserRole.ketuaTim);
    });

    test('AuthService.login authenticates Maria Fernanda De Vega (Admin LKSDM)', () async {
      final user = await AuthService.login(
        email: 'maria.fernanda.de.vega@brin.go.id',
        password: 'Password123!',
      );

      expect(user.name, contains('Maria Fernanda'));
      expect(user.userRole, UserRole.adminLksdm);
    });

    test('AuthService.login rejects unlisted email not present in Supabase', () async {
      expect(
        () => AuthService.login(
          email: 'unknown.fake.account@brin.go.id',
          password: 'Password123!',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
